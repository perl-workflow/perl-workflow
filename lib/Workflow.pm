package Workflow;

# $Id$

use strict;

use base qw( Workflow::Base );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( workflow_error );
use Workflow::Factory   qw( FACTORY );

my @FIELDS = qw( id type description state );
__PACKAGE__->mk_accessors( @FIELDS );

$Workflow::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

use constant NO_CHANGE_VALUE => 'NOCHANGE';

########################################
# OBJECT METHODS

sub init {
    my ( $self, $current_state, $config, $wf_state_objects, $id ) = @_;

    my $log = get_logger();
    $log->info( "Creating a new workflow of type '$config->{properties}{type}' ",
                "with current state '$current_state'" );

    if ( $id ) {
        $self->id( $id );
    }

    my %copy_config = %{ $config };
    $self->state( $current_state );
    $self->type( $copy_config{type} );
    $self->description( $copy_config{description} );
    delete @copy_config{ qw( type description ) };

    # other properties go into 'param'...
    while ( my ( $key, $value ) = each %{ $copy_config } ) {
        next unless ( $key eq 'state' );
        $self->param( $key, $value );
    }

    # Now set all the Workflow::State objects created and cached by the
    # factory

    foreach my $wf_state ( @{ $wf_state_objects } ) {
        $self->_set_workflow_state( $wf_state );
    }
}


sub context {
    my ( $self, $context ) = @_;
    if ( $context ) {

        # We already have a context, merge the new one with ours; (the
        # new one wins with dupes)

        if ( $self->{context} ) {
            $self->{context}->merge( $context );
        }
        else {
            $context->param( workflow_id => $self->id );
            $self->{context} = $context;
        }
    }
    unless ( $self->{context} ) {
        $self->{context} = WorkflowContext->new();
    }
    return $self->{context};
}

sub execute_action {
    my ( $self, $action_name ) = @_;
    my $log = get_logger();

    # Don't eval {} these Action methods, let exceptions bubble up
    # from here...

    my $action = $self->_get_action( $action_name );
    $action->validate( $self );
    $action->execute( $self );

    my $new_state = $self->_get_next_state( $action_name );
    if ( $new_state and $new_state ne NO_CHANGE_VALUE ) {
        $log->info( "Going to new state '$new_state'" );
        $self->state( $new_state );
    }

    # this will save the workflow histories as well; if it fails we
    # should have some means for the factory to rollback other
    # transactions...

    FACTORY->save_workflow( $self );
}

sub get_current_actions {
    my ( $self ) = @_;
    my $wf_state = $self->_get_workflow_state;
    return $wf_state->get_available_action_names( $self );
}

sub get_action_fields {
    my ( $self, $action_name ) = @_;
    my $action = $self->_get_action( $action_name );
    return $action->fields;
}

sub _get_action {
    my ( $self, $action_name ) = @_;
    my $log = get_logger();

    my $state = $self->state;
    $log->debug( "Trying to find action '$action_name' in state '$state'" );

    my $wf_state = $self->_get_workflow_state;
    unless ( $wf_state->contains_action( $action_name ) ) {
        workflow_error "State '$state' does not contain action '$action_name'";
    }
    $log->debug( "Action '$action_name' exists in state '$state'" );

    my $action = FACTORY->get_action( $self, $action_name );

    # This will throw an exception which we want to bubble up

    $wf_state->evaluate_action( $self, $action_name );
    return $action;
}

sub _get_workflow_state {
    my ( $self, $state ) = @_;
    $state ||= $self->state;
    my $wf_state = $self->{_states}{ $state };
    unless ( $wf_state ) {
        workflow_error "No state '$state' exists in workflow '", $self->type, "'";
    }
    return $wf_state;
}

sub _set_workflow_state {
    my ( $self, $wf_state ) = @_;
    $self->{_states}{ $wf_state->state } = $wf_state;
}


sub _get_next_state {
    my ( $self, $action_name ) = @_;
    my $wf_state = $self->_get_workflow_state;
    return $wf_state->get_next_state( $action_name );
}


########################################
# HISTORY

sub add_history {
    my ( $self, $params ) = @_;
    $params->{workflow_id} = $self->id;
    push @{ $self->{_histories} }, Workflow::History->new( $params );
}

sub get_history {
    my ( $self ) = @_;
    my @saved_history = FACTORY->get_workflow_history( $self );
    return ( @{ $self->{_histories} }, @saved_history );
}

sub clear_history {
    my ( $self ) = @_;
    $self->{_histories} = [];
}

1;

__END__

=head1 NAME

Workflow - Object to represent and move between application states

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 PUBLIC METHODS

=head2 Object Methods

B<execute_action( $action_name )>

B<query_action_for_data( $action_name )>

B<add_history( \%params | $wf_history_object )>

B<get_history()>

Returns list of history objects for this workflow. Note that some may
be unsaved.

=head2 Properties

Unless otherwise noted properties are read-only.

=over 4

=item B<id>

ID of this workflow. This will B<always> be defined, since when the
L<Workflow::Factory> creates a new workflow it first ensures the
workflow is saved.

=item B<type>

Type of workflow this is. You may have many individual workflows
associated with a type.

=item B<description>

Description (usually brief, hopefully with a URL...)  of this
workflow.

=item B<state>

The current state of the workflow.

=item B<context> (read-write, see below)

A L<Workflow::Context> object associated with this workflow. If one does
not already exist in the workflow the workflow will create a new one.

If you add a context to a workflow and one already exists, the values
from the new workflow will overwrite values in the existing
workflow. This is a shallow merge, so with the following:

 $wf->context->param( drinks => [ 'coke', 'pepsi' ] );
 my $context = WorkflowContext->new();
 $context->param( drinks => [ 'beer', 'wine' ] );
 $wf->context( $context );
 print 'Current drinks: ', join( ', ', @{ $wf->context->param( 'drinks' ) } );

You will see:

 Current drinks: beer, wine

=back

=head1 INTERNAL METHODS

=head2 Object Methods

B<init( $current_state, \%workflow_config, \@wf_states )>

B<THIS SHOULD ONLY BE CALLED BY THE WorkflowFactory> Do not call this
or the C<new()> method yourself. Your only interface for creating and
fetching workflows is through the factory.

This is called by the inherited constructor and sets the
C<$current_state> value to the property C<state> and uses the other
non-state values from C<\%config> to set parameters via the inherited
C<param()>.

B<_get_action( $action_name )>

Retrieves the action object associated with C<$action_name> in the
current workflow state. This will throw an exception if:

=over 4

=item *

No workflow state exists with a name of the current state. (This is
usually some sort of configuration error and should be caught at
initialization time.)

=item *

No action C<$action_name> exists in the current state.

=item *

No action C<$action_name> exists in the workflow universe.

=item *

One of the conditions for the action in this state is not met.

=back

B<_evaluate_conditions( $action_name, @conditions )>

B<_get_workflow_state( [ $state ] )>

C<$state> defaults to the current state

B<_set_workflow_state( $wf_state )>

B<_get_next_state()>

=head1 SEE ALSO

L<Workflow::Factory>

L<Workflow::Context>

L<Workflow::State>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
