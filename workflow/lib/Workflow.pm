package Workflow;

# $Id$

use strict;

use base qw( Workflow::Base );
use Log::Log4perl       qw( get_logger );
use Workflow::Context;
use Workflow::Exception qw( workflow_error );
use Workflow::Factory   qw( FACTORY );

my @FIELDS = qw( id description last_update state type );
__PACKAGE__->mk_accessors( @FIELDS );

$Workflow::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

use constant NO_CHANGE_VALUE => 'NOCHANGE';

########################################
# PUBLIC METHODS

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
        $self->{context} = Workflow::Context->new();
    }
    return $self->{context};
}

sub get_current_actions {
    my ( $self ) = @_;
    my $log = get_logger();
    $log->debug( "Getting current actions for wf '", $self->id, "'" );
    my $wf_state = $self->_get_workflow_state;
    return $wf_state->get_available_action_names( $self );
}

sub get_action_fields {
    my ( $self, $action_name ) = @_;
    my $action = $self->_get_action( $action_name );
    return $action->fields;
}

sub execute_action {
    my ( $self, $action_name ) = @_;
    my $log = get_logger();

    # This checks the conditions behind the scenes, so there's no
    # explicit 'check conditions' step here

    my $action = $self->_get_action( $action_name );

    # Set the state to the new workflow state for the action(s) to use
    # for reporting, etc. If an error occurs we have the old state to
    # reset the workflow

    my $old_state = $self->state;
    my $new_state = $self->_get_next_state( $action_name );
    if ( $new_state and $new_state ne NO_CHANGE_VALUE ) {
        $log->info( "Setting new state '$new_state' before action executes" );
        $self->state( $new_state );
    }

    eval {
        $action->validate( $self );
        $log->debug( "Action validated ok" );
        $action->execute( $self );
        $log->debug( "Action executed ok" );

        # this will save the workflow histories as well; if it fails
        # we should have some means for the factory to rollback other
        # transactions...

        FACTORY->save_workflow( $self );
        $log->info( "Saved workflow with possible new state ok" );
    };

    # If there's an exception, reset the state to the original one and
    # rethrow

    if ( $@ ) {
        my $error = $@;
        $log->error( "Caught exception from action: $error" );
        $log->info( "Resetting workflow to old state '$old_state'" );
        $self->state( $old_state );

        # Don't use 'workflow_error' here since $error should already
        # be a Workflow::Exception object or subclass

        die $error;
    }

    return $self->state;
}

sub add_history {
    my ( $self, @items ) = @_;
    my $log = get_logger();

    foreach my $item ( @items ) {
        if ( ref $item eq 'HASH' ) {
            $item->{workflow_id} = $self->id;
            push @{ $self->{_histories} }, Workflow::History->new( $item );
            $log->debug( "Adding history from hashref" );
        }
        elsif ( UNIVERSAL::isa( $item, 'Workflow::History' ) ) {
            $item->workflow_id( $self->id );
            push @{ $self->{_histories} }, $item;
            $log->debug( "Adding history object directly" );
        }
        else {
            workflow_error "I don't know how to add a history of ",
                           "type '", ref( $item ), "'";
        }
    }
}

sub get_history {
    my ( $self ) = @_;
    $self->{_histories} ||= [];
    my @uniq_history = ();
    my %seen_ids = ();
    my @all_history = ( FACTORY->get_workflow_history( $self ),
                        @{ $self->{_histories} } );
    foreach my $history ( @all_history ) {
        my $id = $history->id;
        if ( $id ) {
            unless ( $seen_ids{ $id } ) {
                push @uniq_history, $history;
            }
            $seen_ids{ $id }++;
        }
        else {
            push @uniq_history, $history;
        }
    }
    return @uniq_history;
}

sub get_unsaved_history {
    my ( $self ) = @_;
    return grep { ! $_->is_saved } @{ $self->{_histories} };
}

sub clear_history {
    my ( $self ) = @_;
    $self->{_histories} = [];
}


########################################
# PRIVATE METHODS

sub init {
    my ( $self, $id, $current_state, $config, $wf_state_objects ) = @_;
    $id ||= '';
    my $log = get_logger();
    $log->info( "Instantiating workflow of with ID '$id' and type ",
                "'$config->{type}' with current state '$current_state'" );

    $self->id( $id ) if ( $id );

    $self->state( $current_state );
    $self->type( $config->{type} );
    $self->description( $config->{description} );

    # other properties go into 'param'...
    while ( my ( $key, $value ) = each %{ $config } ) {
        next if ( $key =~ /^(type|description)$/ );
        next if ( ref $value );
        $log->debug( "Assigning parameter '$key' -> '$value'" );
        $self->param( $key, $value );
    }

    # Now set all the Workflow::State objects created and cached by the
    # factory

    foreach my $wf_state ( @{ $wf_state_objects } ) {
        $self->_set_workflow_state( $wf_state );
    }
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
    my $log = get_logger();
    $state ||= ''; # get rid of -w...
    my $use_state = $state || $self->state;
    $log->debug( "Finding Workflow::State object for state [given: $state] ",
                 "[internal: ", $self->state, "]" );
    my $wf_state = $self->{_states}{ $use_state };
    unless ( $wf_state ) {
        workflow_error "No state '$use_state' exists in workflow '", $self->type, "'";
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


1;

__END__

=head1 NAME

Workflow - Simple, flexible system to implement workflows

=head1 SYNOPSIS

 use Workflow::Factory qw( FACTORY );
 
 # Defines a workflow of type 'myworkflow'
 my $workflow_conf  = 'workflow.xml';
 
 # Defines actions available to the workflow
 my $action_conf    = 'action.xml';
 
 # Defines conditions available to the workflow
 my $condition_conf = 'condition.xml';
 
 # Defines validators available to the actions
 my $validator_conf = 'validator.xml';
 
 FACTORY->add_config_from_file( workflow   => $workflow_conf,
                                action     => $action_conf,
                                condition  => $condition_conf,
                                validator  => $validator_conf );
 
 # Instantiate a new workflow...
 my $workflow = FACTORY->get_workflow( 'myworkflow' );
 print "Workflow ", $workflow->id, " ",
       "currently at state ", $workflow->state, "\n";
 
 # Display available actions...
 print "Available actions: ", $workflow->get_current_actions, "\n";
 
 # Get the data needed for action 'FOO' (assumed to be available in
 # the current state) and display the fieldname and description
 
 print "Action 'Foo' requires the following fields:\n";
 foreach my $field ( $workflow->get_action_fields( 'FOO' ) ) {
     print $field->name, ": ", $field->description,
           "(Required? ", $field->is_required, ")\n";
 }
 
 # Add items for the workflow validators, conditions and actions to
 # work with
 
 my $context = $workflow->context;
 $context->param( current_user => $user );
 $context->param( sections => \@sections );
 $context->param( news => $news );
 
 # Execute one of them
 $workflow->execute_action( 'FOO' );
 
 print "New state: ", $workflow->state, "\n";
 
 # Later.... fetch an existing workflow
 my $id = get_workflow_id_from_user( ... );
 my $workflow = FACTORY->get_workflow( 'myworkflow', $id );
 print "Current state: ", $workflow->state, "\n";

=head1 DESCRIPTION

=head2 Overview

This is a standalone workflow system. It is designed to fit into your
system rather than force your system to fit to it. You can save
workflow information to a database or the filesystem (or a custom
storage). The different components of a workflow system can be
included separately as libraries to allow for maximum reusibility.

=head2 User Point of View

As a user you only see two components, plus a third which is really
embedded into another:

=over 4

=item *

L<Workflow::Factory> - The factory is your interface for creating new
workflows and fetching existing ones. You also feed all the necessary
configuration files and/or data structures to the factory to
initialize it.

=item *

L<Workflow> - When you get the workflow object from the workflow
factory you can only use it in a few ways -- asking for the current
state, actions available for the state, data required for a particular
action, and most importantly, executing a particular action. Executing
an action is how you change from one state to another.

=item *

L<Workflow::Context> - This is a blackboard for data from your
application to the workflow system and back again. Each instantiation
of a L<Workflow> has its own context, and actions executed by the
workflow can read data from and deposit data into the context.

=back

=head2 Developer Point of View

The workflow system has four basic components:

=over 4

=item *

B<workflow> - The workflow is a collection of states; you define the
states, how to move from one state to another, and under what
conditions you can change states.

This is represented by the L<Workflow> object. You normally do not
need to subclass this object and customize it.

=item *

B<action> - The action is defined by you or in a separate library. The
action is triggered by moving from one state to another and has access
to information

The base class for actions is the L<Workflow::Action> class.

=item *

B<condition> - Within the workflow you can attach one or more
conditions to an action. These ensure that actions can only get
executed when certain conditions are met. Conditions are completely
arbitrary: typically they will ensure the user has particular access
rights, but you can also specify that an action can only be executed
at certain times of the day, or from certain IP addresses, and so
forth. Each condition is created once at startup then passed a context
to check every time an action is checked to see if it can be executed.

The base class for conditions is the L<Workflow::Condition> class.

=item *

B<validator> - An action can specify one or more validators to ensure
that the data available to the action is correct. The data to check
can be as simple or complicated as you like. Each validator is created
once then passed a context and data to check every time an action is
executed.

The base class for validators is the L<Workflow::Validator> class.

=back

=head1 WORKFLOW METHODS

The following documentation is for the workflow object itself rather
than the entire system.

=head2 Object Methods

B<execute_action( $action_name )>

Execute the action C<$action_name> which normally changes the state of
the workflow. If C<$action_name> not in the current state, fails one
of the conditions on the action, or fails one of the validators on the
action an exception is thrown.

Returns: new state of workflow

B<get_current_actions()>

Returns a list of action names available from the current state for
the given environment. So if you keep your C<context()> the same if
you call C<execute_action()> with one of the action names you should
not trigger any condition error since the action has already been
screened for conditions.

Returns: list of strings representing available actions

B<get_action_fields( $action_name )>

Return a list of L<Workflow::Action::InputField> objects for the given
C<$action_name>. If C<$action_name> not in the current state or not
accessible by the environment an exception is thrown.

Returns: list of L<Workflow::Action::InputField> objects

B<add_history( \%params | $wf_history_object )>

Adds history to the workflow, typically done by an action in
C<execute_action()> or one of the observers of that action. This
history will not be saved until C<execute_action()> is complete.

Returns: nothing

B<get_history()>

Returns list of history objects for this workflow. Note that some may
be unsaved if you call this during the C<execute_action()> process.

B<get_unsaved_history()>

Returns list of all unsaved history objects for this workflow.

B<clear_history()>

Clears all transient history objects from the workflow object, B<not>
from the long-term storage.

=head2 Properties

Unless otherwise noted properties are read-only.

B<id>

ID of this workflow. This will B<always> be defined, since when the
L<Workflow::Factory> creates a new workflow it first saves it to
long-term storage.

B<type>

Type of workflow this is. You may have many individual workflows
associated with a type.

B<description>

Description (usually brief, hopefully with a URL...)  of this
workflow.

B<state>

The current state of the workflow.

B<context> (read-write, see below)

A L<Workflow::Context> object associated with this workflow. This
should never be undefined as the L<Workflow::Factory> sets an empty
context into the workflow when it is instantiated.

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

=head2 Internal Methods

B<init( $id, $current_state, \%workflow_config, \@wf_states )>

B<THIS SHOULD ONLY BE CALLED BY THE> L<Workflow::Factory>. Do not call
this or the C<new()> method yourself -- you will only get an
exception. Your only interface for creating and fetching workflows is
through the factory.

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
initialization time, so it should not happen.)

=item *

No action C<$action_name> exists in the current state.

=item *

No action C<$action_name> exists in the workflow universe.

=item *

One of the conditions for the action in this state is not met.

=back

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
