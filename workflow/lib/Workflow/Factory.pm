package Workflow::Factory;

# $Id$

use strict;
use base qw( Workflow::Base Exporter );
use DateTime;
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( configuration_error workflow_error );

$Workflow::Factory::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my ( $INSTANCE );
sub FACTORY { return $INSTANCE }
@Workflow::Factory::EXPORT_OK = qw( FACTORY );

require Workflow;
require Workflow::Action;
require Workflow::Condition;
require Workflow::Config;
require Workflow::Context;
require Workflow::Persister;
require Workflow::State;
require Workflow::Validator;

my $INITIAL_STATE = 'INITIAL';

my @FIELDS = qw();
__PACKAGE__->mk_accessors( @FIELDS );

sub new {
    workflow_error
        "Please call 'instance()' to get the Workflow::Factory ",
        "rather than instantiating a new one."
}

sub add_config_from_file {
    my ( $self, %params ) = @_;
    my $log = get_logger();
    return unless ( scalar keys %params );

    _check_config_keys( %params );
    foreach my $type ( sort keys %params ) {
        $log->debug( "Using '$type' configuration file(s): ",
                     join( ', ', _flatten( $params{ $type } ) ) );
    }

    $log->debug( "Adding condition configurations..." );
    $self->_add_condition_config(
        Workflow::Config->parse( 'condition', $params{condition} )
    );
    $log->debug( "Adding validator configurations..." );
    $self->_add_validator_config(
        Workflow::Config->parse( 'validator', $params{validator} )
    );
    $log->debug( "Adding persister configurations..." );
    $self->_add_persister_config(
        Workflow::Config->parse( 'persister', $params{persister} )
    );
    $log->debug( "Adding action configurations..." );
    $self->_add_action_config(
        Workflow::Config->parse( 'action', $params{action} )
    );
    $log->debug( "Adding workflow configurations..." );
    $self->_add_workflow_config(
        Workflow::Config->parse( 'workflow', $params{workflow} )
    );
}

sub add_config {
    my ( $self, %params ) = @_;
    return unless ( scalar keys %params );
    _check_config_keys( %params );
    $self->_add_condition_config( _flatten( $params{condition} ) );
    $self->_add_validator_config( _flatten( $params{validator} ) );
    $self->_add_persister_config( _flatten( $params{persister} ) );
    $self->_add_action_config( _flatten( $params{action} ) );
    $self->_add_workflow_config( _flatten( $params{workflow} ) );
}

sub _check_config_keys {
    my ( %params ) = @_;
    my $conf = Workflow::Config->new();
    my @bad_keys = grep { ! $conf->is_valid_config_type( $_ ) } keys %params;
    if ( scalar @bad_keys ) {
        workflow_error "You tried to add configuration information to the ",
                       "workflow factory with one or more bad keys: ",
                       join( ', ', @bad_keys ), ". The following are the ",
                       "keys you have to choose from: ",
                       join( ', ', $conf->get_valid_config_types ), '.';
    }
}

sub _flatten {
    my ( $item ) = @_;
    return ( ref $item eq 'ARRAY' ) ? @{ $item } : ( $item );
}

sub instance {
    return $INSTANCE;
}

########################################
# WORKFLOW

sub _add_workflow_config {
    my ( $self, @all_workflow_config ) = @_;
    my $log = get_logger();
    return unless ( scalar @all_workflow_config );

    foreach my $workflow_config ( @all_workflow_config ) {
        my $wf_type = $workflow_config->{type};
        $self->{_workflow_config}{ $wf_type } = $workflow_config;

        # Create Workflow::State objects for each configured state.
        # When we instantiate a new workflow we pass these objects

        foreach my $state_conf ( @{ $workflow_config->{state} } ) {
            my $wf_state = Workflow::State->new( $state_conf );
            push @{ $self->{_workflow_state}{ $wf_type } }, $wf_state;
        }
        $log->info( "Added all workflow states..." );
    }
}

sub create_workflow {
    my ( $self, $wf_type ) = @_;
    my $log = get_logger();

    my $wf_config = $self->_get_workflow_config( $wf_type );
    unless ( $wf_config ) {
        workflow_error "No workflow of type '$wf_type' available";
    }
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $wf = Workflow->new( undef,
                            $INITIAL_STATE,
                            $wf_config,
                            $self->{_workflow_state}{ $wf_type } );
    $wf->context( Workflow::Context->new );
    my $id = $persister->create_workflow( $wf );
    $wf->id( $id );
    $persister->create_history(
        $wf, Workflow::History->new(
                 { workflow_id => $id,
                   action      => 'Create workflow',
                   description => 'Create new workflow',
                   user        => 'n/a',
                   state       => $wf->state,
                   date        => DateTime->now,
               })
    );
    $wf->last_update( DateTime->now );
    return $wf;
}

sub fetch_workflow {
    my ( $self, $wf_type, $wf_id ) = @_;
    my $log = get_logger();

    my $wf_config = $self->_get_workflow_config( $wf_type );
    unless ( $wf_config ) {
        workflow_error "No workflow of type '$wf_type' available";
    }
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $wf_info = $persister->fetch_workflow( $wf_id );
    return undef unless ( $wf_info );
    $log->debug( "Fetched data for workflow '$wf_id' ok" );
    my $wf = Workflow->new( $wf_id,
                            $wf_info->{state},
                            $wf_config,
                            $self->{_workflow_state}{ $wf_type } );
    $wf->context( Workflow::Context->new );
    $wf->last_update( $wf_info->{last_update} );

    $persister->fetch_extra_workflow_data( $wf );

    return $wf;
}

sub _get_workflow_config {
    my ( $self, $wf_type ) = @_;
    return $self->{_workflow_config}{ $wf_type };
}

sub _insert_workflow {
    my ( $self, $wf ) = @_;
    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $id = $persister->create_workflow( $wf );
    $wf->id( $id );
    return $wf;

}

sub save_workflow {
    my ( $self, $wf ) = @_;
    my $log = get_logger();

    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    $persister->update_workflow( $wf );
    $log->info( "Workflow '", $wf->id, "' updated ok" );
    $persister->create_history( $wf, $wf->get_unsaved_history );
    $log->info( "Created necessary history objects ok" );
    return $wf;
}

sub get_workflow_history {
    my ( $self, $wf ) = @_;
    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    return $persister->fetch_history( $wf );
}


########################################
# ACTIONS

sub _add_action_config {
    my ( $self, @all_action_config ) = @_;
    my $log = get_logger();
    return unless ( scalar @all_action_config );

    foreach my $action_config ( @all_action_config ) {
        my $name = $action_config->{name};
        $log->debug( "Adding configuration for action '$name'" );
        $self->{_action_config}{ $name } = $action_config;
        my $action_class = $action_config->{class};
        unless ( $action_class ) {
            configuration_error "Action '$name' must be associated with a ",
                                "class using the 'class' attribute."
        }
        $log->debug( "Trying to include action class '$action_class'..." );
        eval "require $action_class";
        if ( $@ ) {
            configuration_error "Cannot include action class '$action_class': $@";
        }
        $log->debug( "Included action '$name' class '$action_class' ok" );
    }
}

sub get_action {
    my ( $self, $wf, $action_name ) = @_;
    my $config = $self->{_action_config}{ $action_name };
    unless ( $config ) {
        workflow_error "No action with name '$action_name' available";
    }
    my $action_class = $config->{class};
    return $action_class->new( $wf, $config );
}


########################################
# PERSISTERS

sub _add_persister_config {
    my ( $self, @all_persister_config ) = @_;
    my $log = get_logger();
    return unless ( scalar @all_persister_config );

    foreach my $persister_config ( @all_persister_config ) {
        my $name = $persister_config->{name};
        $log->debug( "Adding configuration for persister '$name'" );
        $self->{_persister_config}{ $name } = $persister_config;
        my $persister_class = $persister_config->{class};
        unless ( $persister_class ) {
            configuration_error "You must specify a 'class' in persister ",
                                "'$name' configuration";
        }
        $log->debug( "Trying to include persister class '$persister_class'..." );
        eval "require $persister_class";
        if ( $@ ) {
            configuration_error "Cannot include persister class ",
                                "'$persister_class': $@";
        }
        $log->debug( "Included persister '$name' class '$persister_class' ",
                     "ok; now try to instantiate persister..." );
        my $persister = eval { $persister_class->new( $persister_config ) };
        if ( $@ ) {
            configuration_error "Failed to create instance of persister ",
                                "'$name' of class '$persister_class': $@";
        }
        $self->{_persister}{ $name } = $persister;
        $log->debug( "Instantiated persister '$name' ok" );
    }
}

sub get_persister {
    my ( $self, $persister_name ) = @_;
    my $persister = $self->{_persister}{ $persister_name };
    unless ( $persister ) {
        workflow_error "No persister with name '$persister_name' available";
    }
    return $persister;
}


########################################
# CONDITIONS

sub _add_condition_config {
    my ( $self, @all_condition_config ) = @_;
    return unless ( scalar @all_condition_config );
    my $log = get_logger();

    foreach my $condition_config ( @all_condition_config ) {
        my $name = $condition_config->{name};
        $log->debug( "Adding configuration for condition '$name'" );
        $self->{_condition_config}{ $name } = $condition_config;
        my $condition_class = $condition_config->{class};
        unless ( $condition_class ) {
            configuration_error "Condition '$name' must be associated ",
                                "with a class using the 'class' attribute";
        }
        $log->debug( "Trying to include condition class '$condition_class'" );
        eval "require $condition_class";
        if ( $@ ) {
            configuration_error "Cannot include condition class ",
                                "'$condition_class': $@";
        }
        $log->debug( "Included condition '$name' class '$condition_class' ",
                     "ok; now try to instantiate condition..." );
        my $condition = eval { $condition_class->new( $condition_config ) };
        if ( $@ ) {
            configuration_error "Cannot create condition '$name': $@";
        }
        $self->{_conditions}{ $name } = $condition;
        $log->debug( "Instantiated condition '$name' ok" );
    }
}

sub get_condition {
    my ( $self, $name ) = @_;
    unless ( $self->{_conditions}{ $name } ) {
        workflow_error "No condition with name '$name' available";
    }
    return $self->{_conditions}{ $name };
}


########################################
# VALIDATORS

sub _add_validator_config {
    my ( $self, @all_validator_config ) = @_;
    return unless ( @all_validator_config );
    my $log = get_logger();

    foreach my $validator_config ( @all_validator_config ) {
        my $name = $validator_config->{name};
        $log->debug( "Adding configuration for validator '$name'" );
        $self->{_validator_config}{ $name } = $validator_config;
        my $validator_class = $validator_config->{class};
        unless ( $validator_class ) {
            configuration_error "Validator '$name' must be associated with ",
                                "a class using the 'class' attribute."
        }
        $log->debug( "Trying to include validator class '$validator_class'" );
        eval "require $validator_class";
        if ( $@ ) {
            workflow_error "Cannot include validator class '$validator_class': $@";
        }
        $log->debug( "Included validator '$name' class '$validator_class' ok; ",
                     "now try to instantiate validator..." );
        my $validator = eval { $validator_class->new( $validator_config ) };
        if ( $@ ) {
            workflow_error "Cannot create validator '$name': $@";
        }
        $self->{_validators}{ $name } = $validator;
        $log->debug( "Instantiated validator '$name' ok" );
    }
}

sub get_validator {
    my ( $self, $name ) = @_;
    unless ( $self->{_validators}{ $name } ) {
        workflow_error "No validator with name '$name' available";
    }
    return $self->{_validators}{ $name };
}

# Create our single instance...
$INSTANCE = bless( {}, __PACKAGE__ );

1;

__END__

=head1 NAME

Workflow::Factory - Generates new workflow and supporting objects

=head1 SYNOPSIS

 # Import the singleton for easy access
 use Workflow::Factory qw( FACTORY );
 
 # Add XML configurations to the factory
 FACTORY->add_config_from_file( workflow  => 'workflow.xml',
                                action    => [ 'myactions.xml', 'otheractions.xml' ],
                                validator => [ 'validator.xml', 'myvalidators.xml' ],
                                condition => 'condition.xml',
                                persister => 'persister.xml' );
 
 # Create a new workflow of type 'MyWorkflow'
 my $wf = FACTORY->create_workflow( 'MyWorkflow' );
 
 # Fetch an existing workflow with ID '25'
 my $wf = FACTORY->fetch_workflow( 'MyWorkflow', 25 );

=head1 DESCRIPTION

=head2 Public

The Workflow Factory is your primary interface to the workflow
system. You give it the configuration files and/or data structures for
the L<Workflow>, L<Workflow::Action>, L<Workflow::Condition>,
L<Workflow::Persister>, and L<Workflow::Validator> objects and then
you ask it for new and existing L<Workflow> objects.

=head2 Internal

Developers using the workflow system should be familiar with how the
factory processes configurations and how it makes the various
components of the system are instantiated and stored in the factory.

=head1 METHODS

=head2 Public Methods

B<instance()>

The factory is a singleton, this is how you get access to the
instance. You can also just import the 'FACTORY' constant as in the
L<SYNOPSIS>.

B<create_workflow( $workflow_type )>

Create a new workflow of type C<$workflow_type>. This will create a
new record in whatever persistence mechanism you have associated with
C<$workflow_type> and set the workflow to its initial state.

Returns: newly created workflow object.

B<fetch_workflow( $workflow_type, $workflow_id )>

Retrieve a workflow object of type C<$workflow_type> and ID
C<$workflow_id>. (The C<$workflow_type> is necessary so we can fetch
the workflow using the correct persister.) If a workflow with ID
C<$workflow_id> is not found C<undef> is returned.

Throws exception if no workflow type C<$workflow_type> available.

Returns: L<Workflow> object

B<add_config_from_file( %config_declarations )>

Pass in filenames for the various components you wish to initialize
using the keys 'action', 'condition', 'persister', 'validator' and
'workflow'. The value for each can be a single filename or an arrayref
of filenames.

The system is familiar with the 'perl' and 'xml' configuration formats
-- see the 'doc/configuration.txt' for what we expect as the
format. Just give your file the right name and it will be read in
properly.

You may also use your own custom configuration file format, read it in
yourself (or subclass L<Workflow::Factory> to do it for you) and add
the resulting hash reference directly to the factory. However, you
need to ensure the configurations are added in the proper order --
when you add an 'action' configuration and reference 'validator'
objects, those objects should already be read in. A good order is:
'validator', 'condition', 'action', 'workflow'. Then just pass the
resulting hash references to C<add_config()> using the right type and
the behavior should be exactly the same.

B<add_config( %config_hashrefs )>

Similar to C<add_config_from_file()> -- the keys may be 'action',
'condition', 'persister', 'validator' and/or 'workflow'. But the
values are the actual configuration hashrefs instead of the files
holding the configurations.

You normally will only need to call this if you are creating
configurations on the fly (e.g., hot-deploying a validator class
specified by a user) or using a custom configuration format.

=head2 Internal Methods

B<save_workflow( $workflow )>

Stores the state and current datetime of the C<$workflow> object. This
is normally called only from the L<Workflow> C<execute_action()>
method.

Returns: C<$workflow>

B<get_workflow_history( $workflow )>

Retrieves all L<Workflow::History> objects related to C<$workflow>.

B<NOTE>: Normal users get the history objects from the L<Workflow>
object itself. Under the covers it calls this.

Returns: list of L<Workflow::History> objects

B<get_action( $workflow, $action_name )>

Retrieves the action C<$action_name> from workflow C<$workflow>. Note
that this does not do any checking as to whether the action is proper
given the state of C<$workflow> or anything like that. It is mostly an
internal method for L<Workflow> (which B<does> do checking as to the
propriety of the action) to instantiate new actions.

Throws exception if no action with name C<$action_name> available.

Returns: L<Workflow::Action> object

B<get_persister( $persister_name )>

Retrieves the persister with name C<$persister_name>.

Throws exception if no persister with name C<$persister_name>
available.

B<get_condition( $condition_name )>

Retrieves the condition with name C<$condition_name>.

Throws exception if no condition with name C<$condition_name>
available.

B<get_validator( $validator_name )>

Retrieves the validator with name C<$validator_name>.

Throws exception if no validator with name C<$validator_name>
available.

=head2 Internal Configuration Methods

B<_add_workflow_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory. Also
cycles through the workflow states and creates a L<Workflow::State>
object for each. These states are passed to the workflow when it is
instantiated.

Returns: nothing

B<_add_action_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
action.

Throws an exception if there is no 'class' associated with an action
or if we cannot 'require' that class.

Returns: nothing

B<_add_persister_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
persister.

Throws an exception if there is no 'class' associated with a
persister, if we cannot 'require' that class, or if we cannot
instantiate an object of that class.

Returns: nothing

B<_add_condition_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
condition.

Throws an exception if there is no 'class' associated with a
condition, if we cannot 'require' that class, or if we cannot
instantiate an object of that class.

Returns: nothing

B<_add_validator_config( @config_hashrefs )>

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
validator.

Throws an exception if there is no 'class' associated with a
validator, if we cannot 'require' that class, or if we cannot
instantiate an object of that class.

Returns: nothing

=head1 SEE ALSO

L<Workflow>

L<Workflow::Action>

L<Workflow::Condition>

L<Workflow::Persister>

L<Workflow::Validator>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
