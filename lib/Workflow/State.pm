package Workflow::State;

use warnings;
use strict;
use v5.14.0;
use parent qw( Workflow::Base );
use Workflow::Condition;
use Workflow::Condition::Evaluate;
use Workflow::Exception qw( workflow_error );
use Exception::Class;
use Workflow::Factory qw( FACTORY );

$Workflow::State::VERSION = '2.07';

my @FIELDS   = qw( state description type );
my @INTERNAL = qw( _test_condition_count _factory _actions _conditions
    _next_state );
__PACKAGE__->mk_accessors( @FIELDS, @INTERNAL );


########################################
# PUBLIC

sub get_conditions {
    my ( $self, $action_name ) = @_;
    $self->_contains_action_check($action_name);
    return @{ $self->_conditions->{$action_name} };
}

sub get_action {
    my ( $self, $wf, $action_name ) = @_;
    my $common_config =
        $self->_factory->get_action_config($wf, $action_name);
    my $state_config  = $self->_actions->{$action_name};
    my $config        = { %{$common_config}, %{$state_config} };
    my $action_class  = $common_config->{class};

    return $action_class->new( $wf, $config );
}

sub contains_action {
    my ( $self, $action_name ) = @_;
    return $self->_actions->{$action_name};
}

sub get_all_action_names {
    my ($self) = @_;
    return keys %{ $self->_actions };
}

sub get_available_action_names {
    my ( $self, $wf, $group ) = @_;
    my @all_actions       = $self->get_all_action_names;
    my @available_actions = ();

    # assuming that the user wants the _fresh_ list of available actions,
    # we clear the condition cache before checking which ones are available
    local $wf->{'_condition_result_cache'} = {};

    foreach my $action_name (@all_actions) {

        if ( $group ) {
            my $action_config =
                $self->_factory()->get_action_config( $wf, $action_name );
            if ( defined $action_config->{group}
                 and $action_config->{group} ne $group ) {
                next;
            }
        }

        if ( $self->is_action_available( $wf, $action_name ) ) {
            push @available_actions, $action_name;
        }
    }
    return @available_actions;
}

sub is_action_available {
    my ( $self, $wf, $action_name ) = @_;
    return $self->evaluate_action( $wf, $action_name );
}

sub clear_condition_cache {
    my ($self) = @_;
    return; # left for backward compatibility with 1.49
}

sub evaluate_action {
    my ( $self, $wf, $action_name ) = @_;
    my $state = $self->state;

    # NOTE: this will throw an exception if C<$action_name> is not
    # contained in this state, so there's no need to do it explicitly

    my @conditions = $self->get_conditions($action_name);
    foreach my $condition (@conditions) {
        my $condition_name = $condition->name;
        my $rv = Workflow::Condition->evaluate_condition($wf, $condition);
        if (! $rv) {

            $self->log->is_debug
                && $self->log->debug(
                "No access to action '$action_name' in ",
                "state '$state' because condition '$condition_name' failed");

            return $rv;
        }
    }

    return 1;
}

sub get_next_state {
    my ( $self, $action_name, $action_return ) = @_;
    $self->_contains_action_check($action_name);
    my $resulting_state = $self->_next_state->{$action_name};
    return $resulting_state unless ( ref($resulting_state) eq 'HASH' );

    return %{$resulting_state} unless(defined $action_return);

    my $state = $self->state;
    workflow_error "State->get_next_state was called with a non-scalar ",
        "return value in state '$state' on action '$action_name'" if (ref $action_return ne '');

    return $resulting_state->{$action_return} if ($resulting_state->{$action_return});

    return $resulting_state->{'*'} if ($resulting_state->{'*'});

    workflow_error "State '$state' does not define a next state ",
        "for a return value of '$action_return' and there is ",
        "also no default state set.";

}

sub get_autorun_action_name {
    my ( $self, $wf ) = @_;
    my $state = $self->state;
    unless ( $self->autorun ) {
        workflow_error "State '$state' is not marked for automatic ",
            "execution. If you want it to be run automatically ",
            "set the 'autorun' property to 'yes'.";
    }

    my @actions   = $self->get_available_action_names($wf);
    my $pre_error = "State '$state' should be automatically executed but";
    if ( scalar @actions > 1 ) {
        workflow_error "$pre_error there are multiple actions available ",
            "for execution. Actions are: ", join ', ', @actions;
    }
    if ( scalar @actions == 0 ) {
        workflow_error
            "$pre_error there are no actions available for execution.";
    }
    $self->log->debug("Auto-running state '$state' with action '$actions[0]'");
    return $actions[0];
}

sub autorun {
    my ( $self, $setting ) = @_;
    if ( defined $setting ) {
        if ( $setting =~ /^(true|1|yes)$/i ) {
            $self->{autorun} = 'yes';
        } else {
            $self->{autorun} = 'no';
        }
    }
    return ( $self->{autorun} eq 'yes' );
}

sub may_stop {
    my ( $self, $setting ) = @_;
    if ( defined $setting ) {
        if ( $setting =~ /^(true|1|yes)$/i ) {
            $self->{may_stop} = 'yes';
        } else {
            $self->{may_stop} = 'no';
        }
    }
    return ( $self->{may_stop} eq 'yes' );
}

########################################
# INTERNAL

sub init {
    my ( $self, $config, $factory ) = @_;

    # Fallback for old style
    $factory ||= FACTORY;
    my $name = $config->{name};

    my $class = ref $self;

    $self->log->debug("Constructing '$class' object for state $name");

    $self->state($name);
    $self->_factory($factory);
    $self->_actions( {} );
    $self->_conditions( {} );
    $self->_next_state( {} );

    # Note this is the workflow type.
    $self->type( $config->{type} );
    $self->description( $config->{description} );

    if ( $config->{autorun} ) {
        $self->autorun( $config->{autorun} );
    } else {
        $self->autorun('no');
    }
    if ( $config->{may_stop} ) {
        $self->may_stop( $config->{may_stop} );
    } else {
        $self->may_stop('no');
    }
    foreach my $state_action_config ( @{ $config->{action} } ) {
        my $action_name = $state_action_config->{name};
        $self->log->debug("Adding action '$action_name' to '$class' '$name'");
        $self->_add_action_config( $action_name, $state_action_config );
    }
}

sub _assign_next_state_from_array {
    my ( $self, $action_name, $resulting ) = @_;
    my $name          = $self->state;
    my @errors        = ();
    my %new_resulting = ();
    foreach my $map ( @{$resulting} ) {
        if ( not $map->{state} or not defined $map->{return} ) {
            push @errors,
                "Must have both 'state' ($map->{state}) and 'return' "
                . "($map->{return}) keys defined.";
        } elsif ( $new_resulting{ $map->{return} } ) {
            push @errors, "The 'return' value ($map->{return}) must be "
                . "unique among the resulting states.";
        } else {
            $new_resulting{ $map->{return} } = $map->{state};
        }
    }
    if ( scalar @errors ) {
        workflow_error "Errors found assigning 'resulting_state' to ",
            "action '$action_name' in state '$name': ", join '; ', @errors;
    }
    $self->log->debug( "Assigned multiple resulting states in '$name' and ",
                       "action '$action_name' from array ok" );
    return \%new_resulting;
}

sub _create_next_state {
    my ( $self, $action_name, $resulting ) = @_;

    if ( my $resulting_type = ref $resulting ) {
        if ( $resulting_type eq 'ARRAY' ) {
            $resulting
                = $self->_assign_next_state_from_array( $action_name,
                                                        $resulting );
        }
    }

    return $resulting;
}

sub _add_action_config {
    my ( $self, $action_name, $action_config ) = @_;
    my $state = $self->state;
    unless ( $action_config->{resulting_state} ) {
        my $no_change_value = Workflow->NO_CHANGE_VALUE;
        workflow_error "Action '$action_name' in state '$state' does not ",
            "have the key 'resulting_state' defined. This key ",
            "is required -- if you do not want the state to ",
            "change, use the value '$no_change_value'.";
    }
    # Copy the action config,
    # so we can delete keys consumed by the state below
    my $copied_config   = { %$action_config };
    my $resulting_state = delete $copied_config->{resulting_state};
    my $condition       = delete $copied_config->{condition};

    # Removes 'resulting_state' key from action_config
    $self->_next_state->{$action_name} =
        $self->_create_next_state( $action_name, $resulting_state );

    # Removes 'condition' key from action_config
    $self->_conditions->{$action_name} = [
        $self->_create_condition_objects( $action_name, $condition )
        ];

    $self->_actions->{$action_name} = $copied_config;
}

sub _create_condition_objects {
    my ( $self, $action_name, $action_conditions ) = @_;
    my @conditions = $self->normalize_array( $action_conditions );
    my @condition_objects = ();
    my $count             = 1;
    foreach my $condition_info (@conditions) {

        # Special case: a 'test' denotes our 'evaluate' condition
        if ( $condition_info->{test} ) {
            my $state  = $self->state();
            push @condition_objects,
                Workflow::Condition::Evaluate->new(
                {   name  => "_$state\_$action_name\_condition\_$count",
                    class => 'Workflow::Condition::Evaluate',
                    test  => $condition_info->{test},
                }
                );
            $count++;
        } else {
            $self->log->info(
                "Fetching condition '$condition_info->{name}'");
            push @condition_objects,
                $self->_factory()
                ->get_condition( $condition_info->{name}, $self->type() );
        }
    }
    return @condition_objects;
}

sub _contains_action_check {
    my ( $self, $action_name ) = @_;
    unless ( $self->contains_action($action_name) ) {
        workflow_error "State '", $self->state, "' does not contain ",
            "action '$action_name'";
    }
}

1;

__END__

=pod

=head1 NAME

Workflow::State - Information about an individual state in a workflow

=head1 VERSION

This documentation describes version 2.07 of this package

=head1 SYNOPSIS

 # This is an internal object...
 <workflow...>
   <state name="Start">
     <description>My state documentation</description> <!-- optional -->
     <action ... resulting_state="Progress" />
   </state>
      ...
   <state name="Progress" description="I am in progress">
     <action ... >
        <resulting_state return="0" state="Needs Affirmation" />
        <resulting_state return="1" state="Approved" />
        <resulting_state return="*" state="Needs More Info" />
     </action>
   </state>
      ...
   <state name="Approved" autorun="yes">
     <action ... resulting_state="Completed" />
      ...

=head1 DESCRIPTION

Each L<Workflow::State> object represents a state in a workflow. Each
state can report its name, description and all available
actions. Given the name of an action it can also report what
conditions are attached to the action and what state will result from
the action (the 'resulting state').

=head2 Resulting State

The resulting state is action-dependent. For instance, in the
following example you can perform two actions from the state 'Ticket
Created' -- 'add comment' and 'edit issue':

  <state name="Ticket Created">
     <action name="add comment"
             resulting_state="NOCHANGE" />
     <action name="edit issue"
             resulting_state="Ticket In Progress" />
   </state>

If you execute 'add comment' the new state of the workflow will be the
same ('NOCHANGE' is a special state). But if you execute 'edit issue'
the new state will be 'Ticket In Progress'.

You can also have multiple return states for a single action. The one
chosen by the workflow system will depend on what the action
returns. For instance we might have something like:

  <state name="create user">
     <action name="create">
         <resulting_state return="admin"    state="Assign as Admin" />
         <resulting_state return="helpdesk" state="Assign as Helpdesk" />
         <resulting_state return="*"        state="Assign as Luser" />
     </action>
  </state>

So if we execute 'create' the workflow will be in one of three states:
'Assign as Admin' if the return value of the 'create' action is
'admin', 'Assign as Helpdesk' if the return is 'helpdesk', and 'Assign
as Luser' if the return is anything else.

=head2 Action availability

A state can have multiple actions associated with it, demonstrated in the
first example under L</Resulting State>. The set of I<available> actions is
a subset of all I<associated> actions: those actions for which none of the
associated conditions fail their check.

  <state name="create user">
     <action name="create">
         ... (resulting_states) ...
         <condition name="can_create_users" />
     </action>
  </state>



=head2 Autorun State

You can also indicate that the state should be automatically executed
when the workflow enters it using the 'autorun' property. Note the
slight change in terminology -- typically we talk about executing an
action, not a state. But we can use both here because an automatically
run state requires that one and only one action is I<available> for
running. That doesn't mean a state contains only one action. It just
means that only one action is I<available> when the state is entered. For
example, you might have two actions with mutually exclusive conditions
within the autorun state.

=head3 Stoppable autorun states

If no action or more than one action is I<available> at the time the
workflow enters an autorun state, Workflow can't continue execution.
If this is isn't a problem, a state may be marked with C<may_stop="yes">:


   <state name="Approved" autorun="yes" may_stop="yes">
     <action name="Archive" resulting_state="Completed" />
        <condition name="allowed_automatic_archival" />
     </action>
  </state>


However, in case the state isn't marked C<may_stop="yes">, Workflow will
throw a C<workflow_error> indicating an autorun problem.


=head1 PUBLIC METHODS

=head3 get_conditions( $action_name )

Returns a list of L<Workflow::Condition> objects for action
C<$action_name>. Throws exception if object does not contain
C<$action_name> at all.

=head3 get_action( $workflow, $action_name )

Returns an L<Workflow::Action> instance initialized using both the
global configuration provided to the named action in the "action
configuration" provided to the factory as well as any configuration
specified as part of the listing of actions in the state of the
workflow declaration.

=head3 contains_action( $action_name )

Returns true if this state contains action C<$action_name>, false if
not.

=head3 is_action_available( $workflow, $action_name )

Returns true if C<$action_name> is contained within this state B<and>
it matches any conditions attached to it, using the data in the
context of the C<$workflow> to do the checks.

=head3 evaluate_action( $workflow, $action_name )

Throws exception if action C<$action_name> is either not contained in
this state or if it does not pass any of the attached conditions,
using the data in the context of C<$workflow> to do the checks.

=head3 get_all_action_names()

Returns list of all action names available in this state.

=head3 get_available_action_names( $workflow, $group )

Returns all actions names that are available given the data in
C<$workflow>. Each action name returned will return true from
B<is_action_available()>.
$group is optional parameter. If it is set, additional check for group
membership will be performed.

=head3 get_next_state( $action_name, [ $action_return ] )

Returns the state(s) that will result if action C<$action_name>
is executed. If you've specified multiple return states in the
configuration then you need to specify the C<$action_return>,
otherwise we return a hash with action return values as the keys and
the action names as the values.

=head3 get_autorun_action_name( $workflow )

Retrieve the action name to be autorun for this state. If the state
does not have the 'autorun' property enabled this throws an
exception. It also throws an exception if there are multiple actions
available or if there are no actions available.

Returns name of action to be used for autorunning the state.

=head3 clear_condition_cache ( )

Deprecated, kept for 2.06 compatibility.

Used to empties the condition result cache for a given state.

=head1 PROPERTIES

All property methods act as a getter and setter. For example:

 my $state_name = $state->state;
 $state->state( 'some name' );

B<state>

Name of this state (required).

B<description>

Description of this state (optional).

=head3 autorun

Returns true if the state should be automatically run, false if
not. To set to true the property value should be 'yes', 'true' or 1.

=head3 may_stop

Returns true if the state may stop automatic execution silently, false
if not. To set to true the property value should be 'yes', 'true' or 1.

=head1 INTERNAL METHODS

=head3 init( $config )

Assigns 'state', 'description', 'autorun' and 'may_stop' properties from
C<$config>. Also assigns configuration for all actions in the state,
performing some sanity checks like ensuring every action has a
'resulting_state' key.

=head1 SEE ALSO

=over

=item * L<Workflow>

=item * L<Workflow::Condition>

=item * L<Workflow::Factory>

=back

=head1 COPYRIGHT

Copyright (c) 2003-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
