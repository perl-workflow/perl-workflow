[![CPAN version](https://badge.fury.io/pl/Workflow.svg)](http://badge.fury.io/pl/Workflow)
[![Build status](https://github.com/jonasbn/perl-workflow/actions/workflows/ci.yml/badge.svg)](https://github.com/jonasbn/perl-workflow/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/jonasbn/perl-workflow/badge.svg?branch=master)](https://coveralls.io/github/jonasbn/perl-workflow?branch=master)

# NAME

Workflow - Simple, flexible system to implement workflows

# VERSION

This documentation describes version 2.00 of Workflow

# SYNOPSIS

    use Workflow::Factory qw( FACTORY );

    # Defines a workflow of type 'myworkflow'
    my $workflow_conf  = 'workflow.xml';

    # contents of 'workflow.xml'

    <workflow>
        <type>myworkflow</type>
        <time_zone>local</time_zone>                         <!-- optional -->
        <description>This is my workflow.</description>      <!-- optional -->
        <history_class>My::Workflow::History</history_class> <!-- optional -->

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
    $self->_factory()->add_config_from_file(
        workflow   => $workflow_conf,
        action     => $action_conf,
        condition  => $condition_conf,
        validator  => $validator_conf
    );

    # Instantiate a new workflow...
    my $workflow = $self->_factory()->create_workflow( 'myworkflow' );
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

    # Execute one of them
    $workflow->execute_action( 'upload file',
                               { path => $path_to_file });

    print "New state: ", $workflow->state, "\n";

    # Later.... fetch an existing workflow
    my $id = get_workflow_id_from_user( ... );
    my $workflow = $self->_factory()->fetch_workflow( 'myworkflow', $id );
    print "Current state: ", $workflow->state, "\n";

# QUICK START

The `eg/ticket/` directory contains a configured workflow system.
You can access the same data and logic in two ways:

- a command-line application (ticket.pl)
- a CGI script               (ticket.cgi)
- a web application          (ticket\_web.pl)

To initialize:

        perl ticket.pl --db

To run the command-line application:

        perl ticket.pl

To access the database and data from CGI, add the relevant
configuration for your web server and call ticket.cgi:

        http://www.mysite.com/workflow/ticket.cgi

To start up the standalone web server:

        perl ticket_web.pl

(Barring changes to HTTP::Daemon and forking the standalone server
won't work on Win32; use CGI instead, although patches are always
welcome.)

For more info, see `eg/ticket/README`

# DESCRIPTION

## Overview

This is a standalone workflow system. It is designed to fit into your
system rather than force your system to fit to it. You can save
workflow information to a database or the filesystem (or a custom
storage). The different components of a workflow system can be
included separately as libraries to allow for maximum reusibility.

## User Point of View

As a user you only see two components, plus a third which is really
embedded into another:

- [Workflow::Factory](https://metacpan.org/pod/Workflow%3A%3AFactory) - The factory is your interface for creating new
workflows and fetching existing ones. You also feed all the necessary
configuration files and/or data structures to the factory to
initialize it.
- [Workflow](https://metacpan.org/pod/Workflow) - When you get the workflow object from the workflow
factory you can only use it in a few ways -- asking for the current
state, actions available for the state, data required for a particular
action, and most importantly, executing a particular action. Executing
an action is how you change from one state to another.
- [Workflow::Context](https://metacpan.org/pod/Workflow%3A%3AContext) - This is a blackboard for data from your
application to the workflow system and back again. Each instantiation
of a [Workflow](https://metacpan.org/pod/Workflow) has its own context, and actions executed by the
workflow can read data from and deposit data into the context.

## Developer Point of View

The workflow system has four basic components:

- **workflow** - The workflow is a collection of states; you define the
states, how to move from one state to another, and under what
conditions you can change states.

    This is represented by the [Workflow](https://metacpan.org/pod/Workflow) object. You normally do not
    need to subclass this object for customization.

- **action** - The action is defined by you or in a separate library. The
action is triggered by moving from one state to another and has access
to the workflow and more importantly its context.

    The base class for actions is the [Workflow::Action](https://metacpan.org/pod/Workflow%3A%3AAction) class.

- **condition** - Within the workflow you can attach one or more
conditions to an action. These ensure that actions only get executed
when certain conditions are met. Conditions are completely arbitrary:
typically they will ensure the user has particular access rights, but
you can also specify that an action can only be executed at certain
times of the day, or from certain IP addresses, and so forth. Each
condition is created once at startup then passed a context to check
every time an action is checked to see if it can be executed.

    The base class for conditions is the [Workflow::Condition](https://metacpan.org/pod/Workflow%3A%3ACondition) class.

- **validator** - An action can specify one or more validators to ensure
that the data available to the action is correct. The data to check
can be as simple or complicated as you like. Each validator is created
once then passed a context and data to check every time an action is
executed.

    The base class for validators is the [Workflow::Validator](https://metacpan.org/pod/Workflow%3A%3AValidator) class.

# WORKFLOW BASICS

## Just a Bunch of States

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

The workflow action 'create issue' has a property 'resulting\_state',
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

## Discover Information from the Workflow

In addition to declaring what the resulting state will be from an
action the action also has a number of 'field' properties that
describe that data it required to properly execute it.

This is an example of discoverability. This workflow system is setup
so you can ask it what you can do next as well as what is required to
move on. So to use our ticket example we can do this, creating the
workflow and asking it what actions we can execute right now:

    my $wf = Workflow::$self->_factory()->create_workflow( 'Ticket' );
    my @actions = $wf->get_current_actions;

We can also interrogate the workflow about what fields are necessary
to execute a particular action:

    print "To execute the action 'create issue' you must provide:\n\n";
    my @fields = $wf->get_action_fields( 'create issue' );
    foreach my $field ( @fields ) {
        print $field->name, " (Required? ", $field->is_required, ")\n",
              $field->description, "\n\n";
    }

## Provide Information to the Workflow

To allow the workflow to run into multiple environments we must have a
common way to move data between your application, the workflow and the
code that moves it from one state to another.

Whenever the [Workflow::Factory](https://metacpan.org/pod/Workflow%3A%3AFactory) creates a new workflow it associates
the workflow with a [Workflow::Context](https://metacpan.org/pod/Workflow%3A%3AContext) object. The context is what
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

The [Workflow::Context](https://metacpan.org/pod/Workflow%3A%3AContext) object is extremely simple to use -- you ask
a workflow for its context and just get/set parameters on it:

    # Get the username from the Apache object
    my $username = $r->connection->user;

    # ...set it in the context
    $wf->context->param( user => $username );

    # somewhere else you'll need the username:

    $news_object->{created_by} = $wf->context->param( 'user' );

## Controlling What Gets Executed

A typical process for executing an action is:

- Get data from the user
- Fetch a workflow
- Set the data from the user to the workflow context
- Execute an action on the context

When you execute the action a number of checks occur. The action needs
to ensure:

- The data presented to it are valid -- date formats, etc. This is done
with a validator, more at [Workflow::Validator](https://metacpan.org/pod/Workflow%3A%3AValidator)
- The environment meets certain conditions -- user is an administrator,
etc. This is done with a condition, more at [Workflow::Condition](https://metacpan.org/pod/Workflow%3A%3ACondition)

Once the action passes these checks and successfully executes we
update the permanent workflow storage with the new state, as long as
the application has declared it.

# WORKFLOWS ARE OBSERVABLE

## Purpose

It's useful to have your workflow generate events so that other parts
of a system can see what's going on and react. For instance, say you
have a new user creation process. You want to email the records of all
users who have a first name of 'Sinead' because you're looking for
your long-lost sister named 'Sinead'. You'd create an observer class
like:

    package FindSinead;

    sub update {
        my ( $class, $wf, $event, $event_args ) = @_;
        return unless ( $event eq 'state change' );
        return unless ( $event_args->{to} eq 'CREATED' );
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

## Events Generated

You can attach listeners to workflows and catch events at a few points
in the workflow lifecycle; these are the events fired:

- **create** - Issued after a workflow is first created.

    No additional parameters.

- **fetch** - Issued after a workflow is fetched from the persister.

    No additional parameters.

- **startup** - Issued at the beginning of the execute loop, before the
first action is called.

    No additional parameters.

- **finalize** - Issued at the end of the execute loop, after all action
are handled.

    No additional parameters.

- **run** - Issued before a single action is executed. Will be followed by
either a `save` or `rollback` event.

    No additional parameters.

- **save** - Issued after the workflow was saved after running a single action.

    No additional parameters.

- **rollback** - Issued after the execution of a single action failed.

    No additional parameters.

- **completed** - Issued after a single action was successfully executed and
saved.

    Receives a hashref as second parameter holding the keys `state` and
    `action`. `$state` includes the state of the workflow before the action
    was executed, `$action` is the action name that was executed.

- **state change** - Issued after a single action is successfully executed,
saved and results in a state change. The event will not be fired if
you executed an action that did not result in a state change.

    Receives a hashref as second parameter. The key `from` holds the name
    of the state before the action, `action` is the name of the action
    that was executed and `to` holding the name of the target (current) state.

- **add history** - Issued after one or more history objects were added to
a workflow object.

    The additional argument is an arrayref of all [Workflow::History](https://metacpan.org/pod/Workflow%3A%3AHistory)
    objects added to the workflow. (Note that these will not be persisted
    until the workflow is persisted.)

## Configuring

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
will catch observations using its `update()` method. In the second
we're naming exactly the subroutine ('other\_sub()' in the class
'SomeOtherObserver::Functions') that will catch observations.

All configured observers get all events. It's up to each observer to
figure out what it wants to handle.

# WORKFLOW METHODS

The following documentation is for the workflow object itself rather
than the entire system.

## Object Methods

### execute\_action( $action\_name, $args )

Execute the action `$action_name`. Typically this changes the state
of the workflow. If `$action_name` is not in the current state, fails
one of the conditions on the action, or fails one of the validators on
the action an exception is thrown.

The `$args` provided, are checked against the validators to ensure the
context remains in a valid state; upon successful validation, the `$args`
are merged into the context and the action is executed as described above.

After the action has been successfully executed and the workflow saved
we issue a 'execute' observation with the old state, action name and
an autorun flag as additional parameters.
So if you wanted to write an observer you could create a
method with the signature:

    sub update {
        my ( $class, $workflow, $action, $old_state, $action_name )
           = @_;
        if ( $action eq 'execute' ) { .... }
    }

We also issue a 'change state' observation if the executed action
resulted in a new state. See ["WORKFLOWS ARE OBSERVABLE"](#workflows-are-observable) above for how
we use and register observers.

Returns: new state of workflow

### get\_current\_actions( $group )

Returns a list of action names available from the current state for
the given environment. So if you keep your `context()` the same if
you call `execute_action()` with one of the action names you should
not trigger any condition error since the action has already been
screened for conditions.
If you want to divide actions in groups (for example state change group,
approval group, which have to be shown at different places on the page) add group property
to your action

    <action name="terminate request"  group="state change"  class="MyApp::Action::Terminate" />
    <action name="approve request"  group="approval"  class="MyApp::Action::Approve" />

    my @actions = $wf->get_current_actions("approval");

`$group` should be string that reperesents desired group name. In @actions you will get
list of action names available from the current state for the given environment limited by group.
`$group` is optional parameter.

Returns: list of strings representing available actions

### get\_all\_actions

Returns a list of ALL action names defined for the current state, weather or not
they are available from the current environment.

Returns: list of strings representing available actions

### get\_action( $action\_name )

Retrieves the action object associated with `$action_name` in the
current workflow state. This will throw an exception if:

- No workflow state exists with a name of the current state. (This is
usually some sort of configuration error and should be caught at
initialization time, so it should not happen.)
- No action `$action_name` exists in the current state.
- No action `$action_name` exists in the workflow universe.
- One of the conditions for the action in this state is not met.

### get\_action\_fields( $action\_name )

Return a list of [Workflow::InputField](https://metacpan.org/pod/Workflow%3A%3AInputField) objects for the given
`$action_name`. If `$action_name` not in the current state or not
accessible by the environment an exception is thrown.

Returns: list of [Workflow::InputField](https://metacpan.org/pod/Workflow%3A%3AInputField) objects

### add\_history( @( \\%params | $wf\_history\_object ) )

Adds any number of histories to the workflow, typically done by an
action in `execute_action()` or one of the observers of that
action. This history will not be saved until `execute_action()` is
complete.

You can add a list of either hashrefs with history information in them
or full [Workflow::History](https://metacpan.org/pod/Workflow%3A%3AHistory) objects. Trying to add anything else will
result in an exception and **none** of the items being added.

Successfully adding the history objects results in a 'add history'
observation being thrown. See ["WORKFLOWS ARE OBSERVABLE"](#workflows-are-observable) above for
more.

Returns: nothing

### get\_history()

Returns list of history objects for this workflow. Note that some may
be unsaved if you call this during the `execute_action()` process.

### get\_unsaved\_history()

Returns list of all unsaved history objects for this workflow.

### clear\_history()

Clears all transient history objects from the workflow object, **not**
from the long-term storage.

### set( $property, $value )

Method used to overwrite [Class::Accessor](https://metacpan.org/pod/Class%3A%3AAccessor) so only certain callers can set
properties caller has to be a [Workflow](https://metacpan.org/pod/Workflow) namespace package.

Sets property to value or throws [Workflow::Exception](https://metacpan.org/pod/Workflow%3A%3AException)

## Observer methods

### add\_observer( @observers )

Adds one or more observers to a `Workflow` instance. An observer is a
function. See ["notify\_observers"](#notify_observers) for its calling convention.

This function is used internally by `Workflow::Factory` to implement
observability as documented in the section ["WORKFLOWS ARE OBSERVABLE"](#workflows-are-observable)

### notify\_observers( @arguments )

Calls all observer functions registered through `add_observer` with
the workflow as the first argument and `@arguments` as the remaining
arguments:

    $observer->( $wf, @arguments );

Used by various parts of the library to notify observers of workflow
instance related events.

## Properties

Unless otherwise noted, properties are **read-only**.

### Configuration Properties

Some properties are set in the configuration file for each
workflow. These remain static once the workflow is instantiated.

#### **type**

Type of workflow this is. You may have many individual workflows
associated with a type or you may have many different types
running in a single workflow engine.

#### **description**

Description (usually brief, hopefully with a URL...)  of this
workflow.

#### **time\_zone**

Workflow uses the DateTime module to create all date objects. The time\_zone
parameter allows you to pass a time zone value directly to the DateTime
new method for all cases where Workflow needs to create a date object.
See the DateTime module for acceptable values.

### Dynamic Properties

You can get the following properties from any workflow object.

#### **id**

ID of this workflow. This will **always** be defined, since when the
[Workflow::Factory](https://metacpan.org/pod/Workflow%3A%3AFactory) creates a new workflow it first saves it to
long-term storage.

#### **state**

The current state of the workflow.

#### **last\_update** (read-write)

Date of the workflow's last update.

#### **last\_action\_executed** (read)

Contains the name of the action that was tried to be executed last, even if
the execution could not be completed due to e.g. failed parameter validation,
execption on code execution. Useful to find the step that failed when using
autorun sequences, as `state` will return the state from which it was called.

### context (read-write, see below)

A [Workflow::Context](https://metacpan.org/pod/Workflow%3A%3AContext) object associated with this workflow. This
should never be undefined as the [Workflow::Factory](https://metacpan.org/pod/Workflow%3A%3AFactory) sets an empty
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

## Internal Methods

### init( $id, $current\_state, \\%workflow\_config, \\@wf\_states )

**THIS SHOULD ONLY BE CALLED BY THE** [Workflow::Factory](https://metacpan.org/pod/Workflow%3A%3AFactory). Do not call
this or the `new()` method yourself -- you will only get an
exception. Your only interface for creating and fetching workflows is
through the factory.

This is called by the inherited constructor and sets the
`$current_state` value to the property `state` and uses the other
non-state values from `\%config` to set parameters via the inherited
`param()`.

### \_get\_workflow\_state( \[ $state \] )

Return the [Workflow::State](https://metacpan.org/pod/Workflow%3A%3AState) object corresponding to `$state`, which
defaults to the current state.

### \_set\_workflow\_state( $wf\_state )

Assign the [Workflow::State](https://metacpan.org/pod/Workflow%3A%3AState) object `$wf_state` to the workflow.

### \_get\_next\_state( $action\_name )

Returns the name of the next state given the action
`$action_name`. Throws an exception if `$action_name` not contained
in the current state.

## Initial workflow history

When creating an initial [Workflow::History](https://metacpan.org/pod/Workflow%3A%3AHistory) record when creating a workflow,
several fields are required.

### get\_initial\_history\_data

This method returns a _list_ of key/value pairs to add in the initial history
record. The following defaults are returned:

- `user`

    value: "n/a"

- `description`

    value: "Create new workflow"

- `action`

    value: "Create workflow"

Override this method to change the values from their defaults. E.g.

    sub get_initial_history_data {
       return (
            user => 1,
            description => "none",
            action => "run"
       );
    }

# CONFIGURATION AND ENVIRONMENT

The configuration of Workflow is done using the format of your choice, currently
XML and Perl are implemented, but additional formats can be added. Please refer
to [Workflow::Config](https://metacpan.org/pod/Workflow%3A%3AConfig), for implementation details.

## Configuration examples

### XML configuration

    <workflow>
        <type>myworkflow</type>
        <class>My::Workflow</class>                     <!-- optional -->
        <initial_state>INITIAL</initial_state>          <!-- optional -->
        <time_zone>local</time_zone>                    <!-- optional -->
        <description>This is my workflow.</description> <!-- optional -->

        <!-- List one or more states -->
        <state name="INITIAL">
            <action name="upload file" resulting_state="uploaded" />
            <action name="cancel upload" resulting_state="finished" />
        </state>

        <state name="uploaded">
            <action name="verify file">
               <resulting_state return="redo"     state="INITIAL" />
               <resulting_state return="finished" state="finished"/>
            </action>
        </state>

        <state name="finished" />
    </workflow>

## Logging

As of version 2.0, Workflow allows application developers to select their own
logging solution of preference: The library is a [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) log producer. See
[Log::Any::Adapter](https://metacpan.org/pod/Log%3A%3AAny%3A%3AAdapter) for examples on how to configure logging. For those
wanting to keep running their [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) configuration, please install
[Log::Any::Adapter::Log4perl](https://metacpan.org/pod/Log%3A%3AAny%3A%3AAdapter%3A%3ALog4perl) and add one `use` statement and one line after
the initialization of `Log::Log4perl`:

    use Log::Log4perl;
    use Log::Any::Adapter;   # Add this additional use-statement

    Log::Log4perl::init('/etc/log4perl.conf');
    Log::Any::Adapter->set( 'Log4perl' ); # Additional: Log::Any initialization

# DEPENDENCIES

The full list of dependencies is specified in the cpanfile in the distribution
archive. Additional dependencies are listed by feature. The following features
are currently supported by this distribution:

- `examples`

    The additional dependencies required to run the example applications.

# INCOMPATIBILITIES

## XML::Simple

CPAN testers reports however do demonstrate a problem with one of the
dependencies of Workflow, namely [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple).

The [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple) makes use of [Lib::XML::SAX](https://metacpan.org/pod/Lib%3A%3AXML%3A%3ASAX) or [XML::Parser](https://metacpan.org/pod/XML%3A%3AParser), the default.

In addition [XML::Parser](https://metacpan.org/pod/XML%3A%3AParser) can make use of plugin parsers and some of these
might not be able to parse the XML utilized in Workflow. This problem has been
observed with [XML::SAX::RTF](https://metacpan.org/pod/XML%3A%3ASAX%3A%3ARTF).

The following diagnostic points to the problem:

        No _parse_* routine defined on this driver (If it is a filter, remember to
        set the Parent property. If you call the parse() method, make sure to set a
        Source. You may want to call parse_uri, parse_string or parse_file instead.)

Your [XML::SAX](https://metacpan.org/pod/XML%3A%3ASAX) configuration is located in the file:

        XML/SAX/ParserDetails.ini

# BUGS AND LIMITATIONS

Known bugs and limitations can be seen in the Github issue tracker:

[https://github.com/jonasbn/perl-workflow/issues](https://github.com/jonasbn/perl-workflow/issues)

# BUG REPORTING

Bug reporting should be done either via Github issues

[https://github.com/jonasbn/perl-workflow/issues](https://github.com/jonasbn/perl-workflow/issues)

A list of currently known issues can be seen via the same URL.

# TEST

The test suite can be run using [prove](https://metacpan.org/pod/prove)

    % prove --lib

Some of the tests are reserved for the developers and are only run of the
environment variable TEST\_AUTHOR is set to true. Requirements for these tests
will only be installed through [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla)'s `authordeps` command:

    % dzil authordeps --missing | cpanm --notest

The test to verify the (http/https) links in the POD documentation will only
run when the variable POD\_LINKS is set.

# CODING STYLE

Currently the code is formatted using [Perl::Tidy](https://metacpan.org/pod/Perl%3A%3ATidy). The resource file can be
downloaded from the central repository.

        notes/perltidyrc

# PROJECT

The Workflow project is currently hosted on GitHub

- GitHub: [https://github.com/jonasbn/perl-workflow](https://github.com/jonasbn/perl-workflow)

## REPOSITORY

The code is kept under revision control using Git:

- [https://github.com/jonasbn/perl-workflow/tree/master/](https://github.com/jonasbn/perl-workflow/tree/master/)

## OTHER RESOURCES

- MetaCPAN

    [https://metacpan.org/release/Workflow](https://metacpan.org/release/Workflow)

# COPYRIGHT

Copyright (c) 2003 Chris Winters and Arvato Direct;
Copyright (c) 2004-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHORS

Jonas B. (jonasbn) <jonasbn@cpan.org>, current maintainer.

Chris Winters <chris@cwinters.com>, original author.

The following folks have also helped out (listed here in no particular order):

Thanks for to Michiel W. Beijen for fix to badly formatted URL, included in release 1.52

Several PRs (13 to be exact) from Erik Huelsmann resulting in release 1.49. Yet another
batch of PRs resulted in release 1.50

PR from Mohammad S Anwar correcting some POD errors, included in release 1.49

Bug report from Petr Pisar resulted in release 1.48

Bug report from Tina Müller (tinita) resulted in release 1.47

Bug report from Slaven Rezić resulting in maintenance release 1.45

Feature and bug fix by dtikhonov resulting in 1.40 (first pull request on Github)

Sérgio Alves, patch to timezone handling for workflow history deserialized using
DBI persister resulting in 1.38

Heiko Schlittermann for context serialization patch resulting in 1.36

Scott Harding, for lazy evaluation of conditions and for nested conditions, see
Changes file: 1.35

Oliver Welter, patch implementing custom workflows, see Changes file: 1.35 and
patch related to this in 1.37 and factory subclassing also in 1.35. Improvements
in logging for condition validation in 1.43 and 1.44 and again a patch resulting
in release 1.46

Steven van der Vegt, patch for autorun in initial state and improved exception
handling for validators, see Changes file: 1.34\_1

Andrew O'Brien, patch implementing dynamic reloaded of flows, see Changes file:
1.33

Sergei Vyshenski, bug reports - addressed and included in 1.33, Sergei also
maintains the FreeBSD port

Alejandro Imass, improvements and clarifications, see Changes file: 1.33

Danny Sadinoff, patches to give better control of initial state and history
records for workflow, see Changes file: 1.33

Thomas Erskine, for patch adding new accessors and fixing several bugs see
Changes file 1.33

Ivan Paponov, for patch implementing action groups, see Changes file, 1.33

Robert Stockdale, for patch implementing dynamic names for conditions, see
Changes file, 1.32

Jim Brandt, for patch to Workflow::Config::XML. See Changes file, 0.27 and 0.30

Alexander Klink, for: patches resulting in 0.23, 0.24, 0.25, 0.26 and 0.27

Michael Bell, for patch resulting in 0.22

Martin Bartosch, for bug reporting and giving the solution not even using a
patch (0.19 to 0.20) and a patch resulting in 0.21

Randal Schwartz, for testing 0.18 and swiftly giving feedback (0.18 to 0.19)

Chris Brown, for a patch to [Workflow::Config::Perl](https://metacpan.org/pod/Workflow%3A%3AConfig%3A%3APerl) (0.17 to 0.18)

Dietmar Hanisch <Dietmar.Hanisch@Bertelsmann.de> - Provided
most of the good ideas for the module and an excellent example of
everyday use.

Tom Moertel <tmoertel@cpan.org> gave me the idea for being
able to attach event listeners (observers) to the process.

Michael Roberts <michael@vivtek.com> graciously released the
'Workflow' namespace on CPAN; check out his Workflow toolkit at
[http://www.vivtek.com/wftk/](http://www.vivtek.com/wftk/).

Michael Schwern <schwern@pobox.org> barked via RT about a
dependency problem and CPAN naming issue.

Jim Smith <jgsmith@tamu.edu> - Contributed patches (being able
to subclass [Workflow::Factory](https://metacpan.org/pod/Workflow%3A%3AFactory)) and good ideas.

Martin Winkler <mw@arsnavigandi.de> - Pointed out a bug and a
few other items.
