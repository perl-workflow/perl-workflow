package Workflow::State;

# $Id$

use strict;
use base qw( Workflow::Base );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( workflow_error );
use Workflow::Factory   qw( FACTORY );

$Workflow::State::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( state description );
__PACKAGE__->mk_accessors( @FIELDS );

########################################
# PUBLIC

sub get_conditions {
    my ( $self, $action_name ) = @_;
    $self->_contains_action_check( $action_name );
    return @{ $self->{_conditions}{ $action_name } };
}

sub contains_action {
    my ( $self, $action_name ) = @_;
    return $self->{_actions}{ $action_name };
}

sub get_all_action_names {
    my ( $self ) = @_;
    return keys %{ $self->{_actions} };
}

sub get_available_action_names {
    my ( $self, $wf ) = @_;
    my @all_actions = $self->get_all_action_names;
    my @available_actions = ();
    foreach my $action_name ( @all_actions ) {
        if ( $self->is_action_available( $wf, $action_name ) ) {
            push @available_actions, $action_name;
        }
    }
    return @available_actions;
}

sub is_action_available {
    my ( $self, $wf, $action_name ) = @_;
    eval { $self->evaluate_action( $wf, $action_name ) };
    return ( ! $@ );
}

sub evaluate_action {
    my ( $self, $wf, $action_name ) = @_;
    my $log = get_logger();

    my $state = $self->state;

    # NOTE: this will throw an exception if C<$action_name> is not
    # contained in this state, so there's no need to do it explicitly

    my @conditions = $self->get_conditions( $action_name );
    foreach my $condition ( @conditions ) {
        my $condition_name = $condition->name;
        $log->is_debug &&
            $log->debug( "Will evaluate condition '$condition_name'" );
        eval { $condition->evaluate( $wf ) };
        if ( $@ ) {
            # TODO: We may just want to pass the error up without wrapping it...
            workflow_error "No access to action '$action_name' in ",
                           "state '$state' because: $@";
        }
        $log->is_debug &&
            $log->debug( "Condition '$condition_name' evaluated successfully" );
    }
}

sub get_next_state {
    my ( $self, $action_name, $action_return ) = @_;
    $self->_contains_action_check( $action_name );
    my $result = $self->{_actions}{ $action_name }{resulting_state};
    if ( ref( $result ) eq 'HASH' ) {
        if ( defined $action_return ) {
            return $result->{ $action_return };
        }
        else {
            return values %{ $result };
        }
    }
    return $result;;

}

sub get_autorun_action_name {
    my ( $self, $wf ) = @_;
    my $state = $self->state;
    unless ( $self->autorun ) {
        workflow_error "State '$state' is not marked for automatic ",
                       "execution. If you want it to be run automatically ",
                       "set the 'autorun' property to 'yes'.";
    }
    my $log = get_logger();

    my @actions = $self->get_available_action_names( $wf );
    my $pre_error = "State '$state' should be automatically executed but ";
    if ( scalar @actions > 1 ) {
        workflow_error "$pre_error there are multiple actions available ",
                       "for execution. Actions are: ", join( @actions, ', ' );
    }
    if ( scalar @actions == 0 ) {
        workflow_error "$pre_error there are no actions available for execution.";
    }
    $log->is_debug &&
        $log->debug( "Auto-running state '$state' with action '$actions[0]'" );
    return $actions[0];
}

sub autorun {
    my ( $self, $setting ) = @_;
    if ( $setting =~ /^(true|1|yes)$/i ) {
        $self->{autorun} = 'yes';
    }
    elsif ( defined $setting ) {
        $self->{autorun} = 'no';
    }
    return ( $self->{autorun} eq 'yes' );
}


########################################
# INTERNAL

sub init {
    my ( $self, $config ) = @_;
    my $log = get_logger();
    my $name = $config->{name};
    $self->state( $name );
    $self->description( $config->{description} );
    $self->is_autorun( $config->{autorun} );
    my $class = ref( $self );
    $log->is_debug &&
        $log->debug( "Constructing '$class' object for state $name" );
    foreach my $state_action_config ( @{ $config->{action} } ) {
        my $action_name = $state_action_config->{name};
        $log->debug( "Adding action '$action_name' to '$class' '$name'" );
        $self->_add_action_config( $action_name, $state_action_config );
    }
}

sub _add_action_config {
    my ( $self, $action_name, $action_config ) = @_;
    my $log = get_logger();
    my $state = $self->state;
    unless ( $action_config->{resulting_state} ) {
        my $no_change_value = Workflow->NO_CHANGE_VALUE;
        workflow_error "Action '$action_name' in state '$state' does not ",
                       "have the key 'resulting_state' defined. This key ",
                       "is required -- if you do not want the state to ",
                       "change, use the value '$no_change_value'.";
    }
    $log->is_debug &&
        $log->debug( "Adding '$state' '$action_name' config" );
    $self->{_actions}{ $action_name } = $action_config;
    $self->{_conditions}{ $action_name } =
        [ $self->_create_condition_objects( $action_config ) ];
}

sub _create_condition_objects {
    my ( $self, $action_config ) = @_;
    my $log = get_logger();
    my @conditions = $self->normalize_array( $action_config->{condition} );
    my @condition_objects = ();
    foreach my $condition_info ( @conditions ) {
        $log->is_info &&
            $log->info( "Fetching condition '$condition_info->{name}'" );
        push @condition_objects, FACTORY->get_condition( $condition_info->{name} );
    }
    return @condition_objects;
}

sub _contains_action_check {
    my ( $self, $action_name ) = @_;
    unless ( $self->contains_action( $action_name ) ) {
        workflow_error "State '", $self->state, "' does not contain ",
                       "action '$action_name'"
    }
}

1;

__END__

=head1 NAME

Workflow::State - Information about an individual state in a workflow

=head1 SYNOPSIS

 # This is an internal object...
 <workflow...>
   <state name="Start">
      ...
   <state name="Progress" description="I am in progress">
      ...
   <state name="Approved" autorun=yes">
      ...

=head1 DESCRIPTION

Each L<Workflow::State> object represents a state in a workflow. Each
state can report its name, description and all available
actions. Given the name of an action it can also report what
conditions are attached to the action and what state will result from
the action.

You can also indicate that the state should be automatically executed
when the workflow enters it. Note the slight change in terminology --
typically we talk about executing an action, not a state. But we can
use both here because an automatically run state requires that one and
only one action is available for running.

Note: that being autorunable doesn't mean a state contains only one
action. It just means that only one action is available when the state
is entered. For example, you might have actions with mutually
exclusive conditions within the autorun state.

=head1 PUBLIC METHODS

B<get_conditions( $action_name )>

Returns a list of L<Condition> objects for action
C<$action_name>. Throws exception if object does not contain
C<$action_name> at all.

B<contains_action( $action_name )>

Returns true if this state contains action C<$action_name>, false if
not.

B<is_action_available( $workflow, $action_name )>

Returns true if C<$action_name> is contained within this state B<and>
it matches any conditions attached to it, using the data in the
context of the C<$workflow> to do the checks.

B<evaluate_action( $workflow, $action_name )>

Throws exception if action C<$action_name> is either not contained in
this state or if it does not pass any of the attached conditions,
using the data in the context of C<$workflow> to do the checks.

B<get_all_action_names()>

Returns list of all action names available in this state.

B<get_available_action_names( $workflow )>

Returns all actions names that are available given the data in
C<$workflow>. Each action name returned will return true from
B<is_action_available()>.

B<get_next_state( $action_name, [ $return_value ] )>

Returns the state(s) that will result if action C<$action_name>
executed. If you've specified multiple return states in the
configuration then you need to specify the C<$return_value>, otherwise
we return an array of states.

B<get_autorun_action_name( $workflow )>

Retrieve the action name to be autorun for this state. If the state
does not have the 'autorun' property enabled this throws an
exception. It also throws an exception if there are multiple actions
available or if there are no actions available.

Returns name of action to be used for autorunning the state.

=head1 PROPERTIES

All property methods act as a getter and setter. For example:

 my $state_name = $state->state;
 $state->state( 'some name' );

B<state>

Name of this state (required).

B<description>

Description of this state (optional).

B<autorun>

Returns true if the state should be automatically run, false if
not. To set to true the property value should be 'yes', 'true' or 1.

=head1 INTERNAL METHODS

B<init( $config )>

Assigns 'state', 'description', and 'autorun' properties from
C<$config>. Also assigns configuration for all actions in the state,
performing some sanity checks like ensuring every action has a
'resulting_state' key.

=head1 SEE ALSO

L<Workflow>

L<Workflow::Factory>

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
