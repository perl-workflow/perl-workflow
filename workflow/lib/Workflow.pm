package Workflow;

# $Id$

use strict;

use base qw( Workflow::Base Class::Observable );
use Log::Log4perl       qw( get_logger );
use Workflow::Context;
use Workflow::Exception qw( workflow_error );
use Workflow::Factory   qw( FACTORY );

my @FIELDS = qw( id type description state last_update );
__PACKAGE__->mk_accessors( @FIELDS );

$Workflow::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

use constant NO_CHANGE_VALUE => 'NOCHANGE';

my ( $log );

########################################
# PUBLIC METHODS

# this is our only read-write property...

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
    $log ||= get_logger();
    $log->is_debug &&
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
    my ( $self, $action_name , $autorun ) = @_;
    $log ||= get_logger();

    # This checks the conditions behind the scenes, so there's no
    # explicit 'check conditions' step here

    my $action = $self->_get_action( $action_name );

    # Need this in case we encounter an exception after we store the
    # new state

    my $old_state = $self->state;
    my ( $new_state, $action_return );

    eval {
        $action->validate( $self );
        $log->is_debug && $log->debug( "Action validated ok" );
        $action_return = $action->execute( $self );
        $log->is_debug && $log->debug( "Action executed ok" );

        $new_state = $self->_get_next_state( $action_name, $action_return );
        if ( $new_state ne NO_CHANGE_VALUE ) {
            $log->is_info &&
                $log->info( "Set new state '$new_state' after action executed" );
            $self->state( $new_state );
        }

        # this will save the workflow histories as well as modify the
        # state of the workflow history to reflect the NEW state of
        # the workflow; if it fails we should have some means for the
        # factory to rollback other transactions...

        FACTORY->save_workflow( $self );
        $log->is_info &&
            $log->info( "Saved workflow with possible new state ok" );
    };

    # If there's an exception, reset the state to the original one and
    # rethrow

    if ( $@ ) {
        my $error = $@;
        $log->error( "Caught exception from action: $error; reset ",
                     "workflow to old state '$old_state'" );
        $self->state( $old_state );

        # Don't use 'workflow_error' here since $error should already
        # be a Workflow::Exception object or subclass

        die $error;
    }

    $self->notify_observers( 'execute', $old_state, $action_name, $autorun );

    if ( $old_state ne $new_state ) {
        $self->notify_observers( 'state change', $old_state,
                                 $action_name, $autorun );
    }

    my $new_state_obj = $self->_get_workflow_state;
    if ( $new_state_obj->autorun ) {
        $log->is_info &&
            $log->info( "State '$new_state' marked to be run ",
                        "automatically; executing that state/action..." );
        $self->_auto_execute_state( $new_state_obj );
    }
    return $self->state;
}


sub add_history {
    my ( $self, @items ) = @_;
    $log ||= get_logger();

    my @to_add = ();
    foreach my $item ( @items ) {
        if ( ref $item eq 'HASH' ) {
            $item->{workflow_id} = $self->id;
            push @to_add, Workflow::History->new( $item );
            $log->is_debug && $log->debug( "Adding history from hashref" );
        }
        elsif ( UNIVERSAL::isa( $item, 'Workflow::History' ) ) {
            $item->workflow_id( $self->id );
            push @to_add, $item;
            $log->is_debug && $log->debug( "Adding history object directly" );
        }
        else {
            workflow_error "I don't know how to add a history of ",
                           "type '", ref( $item ), "'";
        }
    }
    push @{ $self->{_histories} }, @to_add;
    $self->notify_observers( 'add history', \@to_add );
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
    $log ||= get_logger();
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
        $log->is_debug &&
            $log->debug( "Assigning parameter '$key' -> '$value'" );
        $self->param( $key, $value );
    }

    # Now set all the Workflow::State objects created and cached by the
    # factory

    foreach my $wf_state ( @{ $wf_state_objects } ) {
        $self->_set_workflow_state( $wf_state );
    }
}

# Override from Class::Accessor so only certain callers can set
# properties

sub set {
    my ( $self, $prop, $value ) = @_;
    my $calling_pkg = (caller(1))[0];
    unless ( $calling_pkg =~ /^Workflow/ ) {
        warn "Tried to set from: ", join( ', ', caller(1) );
        workflow_error "Don't try to use my private setters from '$calling_pkg'!";
    }
    $self->{ $prop } = $value;
}


sub _get_action {
    my ( $self, $action_name ) = @_;
    $log ||= get_logger();

    my $state = $self->state;
    $log->is_debug &&
        $log->debug( "Trying to find action '$action_name' in state '$state'" );

    my $wf_state = $self->_get_workflow_state;
    unless ( $wf_state->contains_action( $action_name ) ) {
        workflow_error "State '$state' does not contain action '$action_name'";
    }
    $log->is_debug &&
        $log->debug( "Action '$action_name' exists in state '$state'" );

    my $action = FACTORY->get_action( $self, $action_name );

    # This will throw an exception which we want to bubble up

    $wf_state->evaluate_action( $self, $action_name );
    return $action;
}


sub _get_workflow_state {
    my ( $self, $state ) = @_;
    $log ||= get_logger();
    $state ||= ''; # get rid of -w...
    my $use_state = $state || $self->state;
    $log->is_debug &&
        $log->debug( "Finding Workflow::State object for state [given: $use_state] ",
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
    my ( $self, $action_name, $action_return ) = @_;
    my $wf_state = $self->_get_workflow_state;
    return $wf_state->get_next_state( $action_name, $action_return );
}


sub _auto_execute_state {
    my ( $self, $wf_state ) = @_;
    $log ||= get_logger();
    my $action_name;
    eval {
        $action_name = $wf_state->get_autorun_action_name( $self );
    };
    if ( $@ ) { # we found an error, possibly more than one or none action
                # are available in this state
        if ( ! $wf_state->may_stop() ) {
            # we are in autorun, but stopping is not allowed, so
            # rethrow
            my $error = $@;
            $error->rethrow();
        }
    }
    else { # everything is fine, execute action
        $log->is_debug &&
            $log->debug( "Found action '$action_name' to execute in ",
                         "autorun state ", $wf_state->state );
        $self->execute_action( $action_name , 1 );
    }
}

1;

__END__

=head1 NAME

Workflow - Simple, flexible system to implement workflows

=head1 SYNOPSIS

 use Workflow::Factory qw( FACTORY );
 
 # Defines a workflow of type 'myworkflow'
 my $workflow_conf  = 'workflow.xml';
 
 # contents of 'workflow.xml'
 
 <workflow>
     <type>myworkflow</type>
     <state name="INITIAL">
         <action name="upload file" resulting_state="uploaded" />
     </state>
     <state name="uploaded" autorun="yes">
         <action name="verify file" resulting_state="verified file">
              <!-- everyone other than 'CWINTERS' must verify -->
              <condition test="$context->{user} ne 'CWINTERS'" />
         </action>
         <action name="null" resulting_state="annotated">
              <condition test="$context->{user} eq 'CWINTERS'" />
         </action>
     </state>
     <state name="verified file">
         <action name="annotate">
             <condition name="can_annotate" />
         </action>
         <action name="null">
             <condition name="!can_annotate" />
         </action>
     </state>
     <state name="annotated" autorun="yes" may_stop="yes">
         <action name="null" resulting_state="finished">
            <condition name="completed" />
         </action>
     </state>
     <state name="finished" />
 </workflow>
 
 # Defines actions available to the workflow
 my $action_conf    = 'action.xml';
 
 # contents of 'action.xml'
 
 <actions>
     <action name="upload file" class="MyApp::Action::Upload">
         <field name="path" label="File Path"
                description="Path to file" is_required="yes" />
     </action>

     <action name="verify file" class="MyApp::Action::Verify">
         <validator name="filesize_cap">
             <arg>$file_size</arg>
         </validator>
     </action>

     <action name="annotate"    class="MyApp::Action::Annotate" />

     <action name="null"        class="Workflow::Action::Null" />
 </actions>
 
 # Defines conditions available to the workflow
 my $condition_conf = 'condition.xml';
 
 # contents of 'condition.xml'
 
 <conditions>
     <condition name="can_annotate"
                class="MyApp::Condition::CanAnnotate" />
 </conditions>

 # Defines validators available to the actions
 my $validator_conf = 'validator.xml';
 
 # contents of 'validator.xml'
 
 <validators>
     <validator name="filesize_cap" class="MyApp::Validator::FileSizeCap">
         <param name="max_size" value="20M" />
     </validator>
 </validators>

 # Stock the factory with the configurations; we can add more later if
 # we want
 FACTORY->add_config_from_file(
     workflow   => $workflow_conf,
     action     => $action_conf,
     condition  => $condition_conf,
     validator  => $validator_conf
 );
 
 # Instantiate a new workflow...
 my $workflow = FACTORY->create_workflow( 'myworkflow' );
 print "Workflow ", $workflow->id, " ",
       "currently at state ", $workflow->state, "\n";
 
 # Display available actions...
 print "Available actions: ", $workflow->get_current_actions, "\n";
 
 # Get the data needed for action 'upload file' (assumed to be
 # available in the current state) and display the fieldname and
 # description
  
 print "Action 'upload file' requires the following fields:\n";
 foreach my $field ( $workflow->get_action_fields( 'FOO' ) ) {
     print $field->name, ": ", $field->description,
           "(Required? ", $field->is_required, ")\n";
 }
  
 # Add data to the workflow context for the validators, conditions and
 # actions to work with
 
 my $context = $workflow->context;
 $context->param( current_user => $user );
 $context->param( sections => \@sections );
 $context->param( path => $path_to_file );
 
 # Execute one of them
 $workflow->execute_action( 'upload file' );
 
 print "New state: ", $workflow->state, "\n";
 
 # Later.... fetch an existing workflow
 my $id = get_workflow_id_from_user( ... );
 my $workflow = FACTORY->fetch_workflow( 'myworkflow', $id );
 print "Current state: ", $workflow->state, "\n";

=head1 DESCRIPTION

This documentation is for version '0.15' of the Workflow module.

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
need to subclass this object for customization.

=item *

B<action> - The action is defined by you or in a separate library. The
action is triggered by moving from one state to another and has access
to the workflow and more importantly its context.

The base class for actions is the L<Workflow::Action> class.

=item *

B<condition> - Within the workflow you can attach one or more
conditions to an action. These ensure that actions only get executed
when certain conditions are met. Conditions are completely arbitrary:
typically they will ensure the user has particular access rights, but
you can also specify that an action can only be executed at certain
times of the day, or from certain IP addresses, and so forth. Each
condition is created once at startup then passed a context to check
every time an action is checked to see if it can be executed.

The base class for conditions is the L<Workflow::Condition> class.

=item *

B<validator> - An action can specify one or more validators to ensure
that the data available to the action is correct. The data to check
can be as simple or complicated as you like. Each validator is created
once then passed a context and data to check every time an action is
executed.

The base class for validators is the L<Workflow::Validator> class.

=back

=head1 WORKFLOW BASICS

=head2 Just a Bunch of States

A workflow is just a bunch of states with rules on how to move between
them. These are known as transitions and are triggered by some sort of
event. A state is just a description of object properties. You can
describe a surprisingly large number of processes as a series of
states and actions to move between them. The application shipped with
this distribution uses a fairly common application to illustrate: the
trouble ticket.

When you create a workflow you have one action available to you:
create a new ticket ('create issue'). The workflow has a state
'INITIAL' when it is first created, but this is just a bootstrapping
exercise since the workflow must always be in some state.

The workflow action 'create issue' has a property 'resulting_state',
which just means: if you execute me properly the workflow will be in
the new state 'CREATED'.

All this talk of 'states' and 'transitions' can be confusing, but just
match them to what happens in real life -- you move from one action to
another and at each step ask: what happens next?

You create a trouble ticket: what happens next? Anyone can add
comments to it and attach files to it while administrators can edit it
and developers can start working on it. Adding comments does not
really change what the ticket is, it just adds
information. Attachments are the same, as is the admin editing the
ticket.

But when someone starts work on the ticket, that is a different
matter. When someone starts work they change the answer to: what
happens next? Whenever the answer to that question changes, that means
the workflow has changed state.

=head2 Discover Information from the Workflow

In addition to declaring what the resulting state will be from an
action the action also has a number of 'field' properties that
describe that data it required to properly execute it.

This is an example of discoverability. This workflow system is setup
so you can ask it what you can do next as well as what is required to
move on. So to use our ticket example we can do this, creating the
workflow and asking it what actions we can execute right now:

 my $wf = Workflow::Factory->create_workflow( 'Ticket' );
 my @actions = $wf->get_current_actions;

We can also interrogate the workflow about what fields are necessary
to execute a particular action:

 print "To execute the action 'create issue' you must provide:\n\n";
 my @fields = $wf->get_action_fields( 'create issue' );
 foreach my $field ( @fields ) {
     print $field->name, " (Required? ", $field->is_required, ")\n",
           $field->description, "\n\n";
 }

=head2 Provide Information to the Workflow

To allow the workflow to run into multiple environments we must have a
common way to move data between your application, the workflow and the
code that moves it from one state to another.

Whenever the L<Workflow::Factory> creates a new workflow it associates
the workflow with a L<Workflow::Context> object. The context is what
moves the data from your application to the workflow and the workflow
actions.

For instance, the workflow has no idea what the 'current user' is. Not
only is it unaware from an application standpoint but it does not
presume to know where to get this information. So you need to tell it,
and you do so through the context.

The fact that the workflow system proscribes very little means it can
be used in lots of different applications and interfaces. If a system
is too closely tied to an interface (like the web) then you have to
create some potentially ugly hacks to create a more convenient avenue
for input to your system (such as an e-mail approving a document).

The L<Workflow::Context> object is extremely simple to use -- you ask
a workflow for its context and just get/set parameters on it:

 # Get the username from the Apache object
 my $username = $r->connection->user;
 
 # ...set it in the context
 $wf->context->param( user => $username );
 
 # somewhere else you'll need the username:
 
 $news_object->{created_by} = $wf->context->param( 'user' );

=head2 Controlling What Gets Executed

A typical process for executing an action is:

=over 4

=item *

Get data from the user

=item *

Fetch a workflow

=item *

Set the data from the user to the workflow context

=item *

Execute an action on the context

=back

When you execute the action a number of checks occur. The action needs
to ensure:

=over 4

=item *

The data presented to it are valid -- date formats, etc. This is done
with a validator, more at L<Workflow::Validator>

=item *

The environment meets certain conditions -- user is an administrator,
etc. This is done with a condition, more at L<Workflow::Condition>

=back

Once the action passes these checks and successfully executes we
update the permanent workflow storage with the new state, as long as
the application has declared it.

=head1 WORKFLOWS ARE OBSERVABLE

=head2 Purpose

It's useful to have your workflow generate events so that other parts
of a system can see what's going on and react. For instance, say you
have a new user creation process. You want to email the records of all
users who have a first name of 'Sinead' because you're looking for
your long-lost sister named 'Sinead'. You'd create an observer class
like:

 package FindSinead;
 
 sub update {
     my ( $class, $wf, $event, $new_state ) = @_;
     return unless ( $event eq 'state change' );
     return unless ( $new_state eq 'CREATED' );
     my $context = $wf->context;
     return unless ( $context->param( 'first_name' ) eq 'Sinead' );

     my $user = $context->param( 'user' );
     my $username = $user->username;
     my $email    = $user->email;
     my $mailer = get_mailer( ... );
     $mailer->send( 'foo@bar.com','Found her!',
                    "We found Sinead under '$username' at '$email' );
 }

And then associate it with your workflow:

 <workflow>
     <type>SomeFlow</type>
     <observer class="FindSinead" />
     ...

Every time you create/fetch a workflow the associated observers are
attached to it.

=head2 Events Generated

You can attach listeners to workflows and catch events at a few points
in the workflow lifecycle; these are the events fired:

=over 4

=item *

B<create> - Issued after a workflow is first created.

No additional parameters.

=item *

B<fetch> - Issued after a workflow is fetched from the persister.

No additional parameters.

=item *

B<save> - Issued after a workflow is successfully saved.

No additional parameters.

=item *

B<execute> - Issued after a workflow is successfully executed and
saved.

Adds the parameters C<$old_state>, C<$action_name> and C<$autorun>.
C<$old_state> includes the state of the workflow before the action
was executed, C<$action_name> is the action name that was executed and
C<$autorun> is set to 1 if the action just executed was started
using autorun.

=item *

B<state change> - Issued after a workflow is successfully executed,
saved and results in a state change. The event will not be fired if
you executed an action that did not result in a state change.

Adds the parameters C<$old_state>, C<$action> and C<$autorun>.
C<$old_state> includes the state of the workflow before the action
was executed, C<$action> is the action name that was executed and
C<$autorun> is set to 1 if the action just executed was autorun.

=item *

B<add history> - Issued after one or more history objects added to a
workflow object.

The additional argument is an arrayref of all L<Workflow::History>
objects added to the workflow. (Note that these will not be persisted
until the workflow is persisted.)

=back

=head2 Configuring

You configure the observers directly in the 'workflow' configuration
item. Each 'observer' may have either a 'class' or 'sub' entry within
it that defines the observer's location.

We load these classes at startup time. So if you specify an observer
that doesn't exist you see the error when the workflow system is
initialized rather than the system tries to use the observer.

For instance, the following defines two observers:

 <workflow>
   <type>ObservedItem</type>
   <description>This is...</description>
  
   <observer class="SomeObserver" />
   <observer sub="SomeOtherObserver::Functions::other_sub" />

In the first declaration we specify the class ('SomeObserver') that
will catch observations using its C<update()> method. In the second
we're naming exactly the subroutine ('other_sub()' in the class
'SomeOtherObserver::Functions') that will catch observations.

All configured observers get all events. It's up to each observer to
figure out what it wants to handle.

=head1 WORKFLOW METHODS

The following documentation is for the workflow object itself rather
than the entire system.

=head2 Object Methods

=head3 execute_action( $action_name, $autorun )

Execute the action C<$action_name>. Typically this changes the state
of the workflow. If C<$action_name> is not in the current state, fails
one of the conditions on the action, or fails one of the validators on
the action an exception is thrown. $autorun is used internally and
is set to 1 if the action was executed using autorun.

After the action has been successfully executed and the workflow saved
we issue a 'execute' observation with the old state, action name and
an autorun flag as additional parameters. 
So if you wanted to write an observer you could create a
method with the signature:

 sub update {
     my ( $class, $workflow, $action, $old_state, $action_name, $autorun )
        = @_;
     if ( $action eq 'execute' ) { .... }
 }

We also issue a 'change state' observation if the executed action
resulted in a new state. See L<WORKFLOWS ARE OBSERVABLE> above for how
we use and register observers and L<Class::Observable> for more
general information about observers as well as implementation details.

Returns: new state of workflow

=head3 get_current_actions()

Returns a list of action names available from the current state for
the given environment. So if you keep your C<context()> the same if
you call C<execute_action()> with one of the action names you should
not trigger any condition error since the action has already been
screened for conditions.

Returns: list of strings representing available actions

=head3 get_action_fields( $action_name )

Return a list of L<Workflow::Action::InputField> objects for the given
C<$action_name>. If C<$action_name> not in the current state or not
accessible by the environment an exception is thrown.

Returns: list of L<Workflow::Action::InputField> objects

=head3 add_history( @( \%params | $wf_history_object ) )

Adds any number of histories to the workflow, typically done by an
action in C<execute_action()> or one of the observers of that
action. This history will not be saved until C<execute_action()> is
complete.

You can add a list of either hashrefs with history information in them
or full L<Workflow::History> objects. Trying to add anything else will
result in an exception and B<none> of the items being added.

Successfully adding the history objects results in a 'add history'
observation being thrown. See L<WORKFLOWS ARE OBSERVABLE> above for
more.

Returns: nothing

=head3 get_history()

Returns list of history objects for this workflow. Note that some may
be unsaved if you call this during the C<execute_action()> process.

=head3 get_unsaved_history()

Returns list of all unsaved history objects for this workflow.

=head3 clear_history()

Clears all transient history objects from the workflow object, B<not>
from the long-term storage.

=head2 Properties

Unless otherwise noted properties are B<read-only>.

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

B<last_update> (read-write)

Date of the workflow's last update.

=head3 context (read-write, see below)

A L<Workflow::Context> object associated with this workflow. This
should never be undefined as the L<Workflow::Factory> sets an empty
context into the workflow when it is instantiated.

If you add a context to a workflow and one already exists, the values
from the new workflow will overwrite values in the existing
workflow. This is a shallow merge, so with the following:

 $wf->context->param( drinks => [ 'coke', 'pepsi' ] );
 my $context = Workflow::Context->new();
 $context->param( drinks => [ 'beer', 'wine' ] );
 $wf->context( $context );
 print 'Current drinks: ', join( ', ', @{ $wf->context->param( 'drinks' ) } );

You will see:

 Current drinks: beer, wine

=head2 Internal Methods

=head3 init( $id, $current_state, \%workflow_config, \@wf_states )

B<THIS SHOULD ONLY BE CALLED BY THE> L<Workflow::Factory>. Do not call
this or the C<new()> method yourself -- you will only get an
exception. Your only interface for creating and fetching workflows is
through the factory.

This is called by the inherited constructor and sets the
C<$current_state> value to the property C<state> and uses the other
non-state values from C<\%config> to set parameters via the inherited
C<param()>.

=head3 _get_action( $action_name )

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

=head3 _get_workflow_state( [ $state ] )

Return the L<Workflow::State> object corresponding to C<$state>, which
defaults to the current state.

=head3 _set_workflow_state( $wf_state )

Assign the L<Workflow::State> object C<$wf_state> to the workflow.

=head3 _get_next_state( $action_name )

Returns the name of the next state given the action
C<$action_name>. Throws an exception if C<$action_name> not contained
in the current state.

#=head3 set

=head1 SEE ALSO

L<Workflow::Context>

L<Workflow::Factory>

L<Workflow::State>

October 2004 talk 'Workflows in Perl' given to
pgh.pm: L<http://www.cwinters.com/pdf/workflow_pgh_pm.pdf>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters and Arvato Direct; 2004, 2005, 2006 
Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt>, current maintainer.

Chris Winters E<lt>chris@cwinters.comE<gt>, original author.

The following folks have also helped out:

Alexander Klink, for: patches resulting in 0.23, 0.24 and 0.25

Michael Bell, for patch resulting in 0.22

Martin Bartosch, for bug reporting and giving the solution not even using a
patch (0.19 to 0.20) and a patch resulting in 0.21

Randal Schwartz, for testing 0.18 and swiftly giving feedback (0.18 to 0.19)

Chris Brown, for a patch to L<Workflow::Config::Perl> (0.17 to 0.18)

Dietmar Hanisch E<lt>Dietmar.Hanisch@Bertelsmann.deE<gt> - Provided
most of the good ideas for the module and an excellent example of
everyday use.

Tom Moertel E<lt>tmoertel@cpan.orgE<gt> gave me the idea for being
able to attach event listeners (observers) to the process.

Michael Roberts E<lt>michael@vivtek.comE<gt> graciously released the
'Workflow' namespace on CPAN; check out his Workflow toolkit at
L<http://www.vivtek.com/wftk.html>.

Michael Schwern E<lt>schwern@pobox.orgE<gt> barked via RT about a
dependency problem and CPAN naming issue.

Jim Smith E<lt>jgsmith@tamu.eduE<gt> - Contributed patches (being able
to subclass L<Workflow::Factory>) and good ideas.

Martin Winkler E<lt>mw@arsnavigandi.deE<gt> - Pointed out a bug and a
few other items.
