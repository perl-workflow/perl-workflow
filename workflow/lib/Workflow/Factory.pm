package Workflow::Factory;

# $Id$

use strict;
use base qw( Workflow::Base Exporter );
use Log::Log4perl qw( get_logger );
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
    return unless ( scalar keys %params );
    _check_config_keys( %params );
    $self->_add_condition_config(
        Workflow::Config->parse( 'condition', $params{condition} )
    );
    $self->_add_validator_config(
        Workflow::Config->parse( 'validator', $params{validator} )
    );
    $self->_add_persister_config(
        Workflow::Config->parse( 'persister', $params{persister} )
    );
    $self->_add_action_config(
        Workflow::Config->parse( 'action', $params{action} )
    );
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
    return unless ( scalar @all_workflow_config );
    foreach my $workflow_config ( @all_workflow_config ) {
        my $wf_type = $workflow_config->{type};
        $self->{_workflow_config}{ $wf_type } = $workflow_config;

        # Ask the workflow class to pull out the state configurations

        my @state_config = Workflow::Config->get_all_state_config( $workflow_config );

        # And create Workflow::State objects for each of them. When we
        # instantiate a new workflow we give it these states

        foreach my $state_conf ( @state_config ) {
            my $wf_state = Workflow::State->new( $state_conf );
            push @{ $self->{_workflow_state}{ $wf_type } }, $wf_state;
        }

        my $persister_conf = $workflow_config->{persister};
        # TODO: allow association of named persister
        my $persister_class = $persister_conf->{class};
        unless ( $persister_class ) {
            configuration_error "Workflow '$wf_type' must be associated with ",
                                "a persister in the key 'persister' along with ",
                                "a subkey 'class' and any associated parameters.";
        }
        my $persister = $persister_class->new( $persister_conf );
        $self->{_workflow_persister}{ $wf_type } = $persister;
    }
}

sub get_workflow {
    my ( $self, $wf_type, $wf_id ) = @_;
    my $log = get_logger();

    my $config = $self->_get_workflow_config( $wf_type );
    unless ( $config ) {
        workflow_error "No workflow of type '$wf_type' available";
    }
    my $persister = $self->_get_persister( $config->{persister} );
    my ( $wf );
    if ( $wf_id ) {
        my $wf_info = $persister->fetch_workflow( $wf_id );
        unless ( $wf_info ) {
            workflow_error "No workflow found with ID '$wf_id'";
        }
        $log->debug( "Fetched data for workflow '$wf_id' ok" );
        my $wf = Workflow->new( $wf_id,
                                $wf_info->{state},
                                $config,
                                $self->{_workflow_state}{ $wf_type } );
        $persister->fetch_extra_workflow_data( $wf );
    }
    else {
        $wf = Workflow->new( $INITIAL_STATE,
                             $config,
                             $self->{_workflow_state}{ $wf_type } );
        my $id = $persister->create_workflow( $wf );
        $wf->id( $id );
    }
    unless ( $wf->context ) {
        $wf->context( Workflow::Context->new );
    }
    return $wf;
}

sub _get_workflow_config {
    my ( $self, $wf_type ) = @_;
    return $self->{_workflow_config}{ $wf_type };
}

sub _insert_workflow {
    my ( $self, $wf ) = @_;
    my $wf_persist = WorkflowPersist->new({ type  => $wf->type,
                                            state => $wf->state });
    $wf_persist->{state} = $wf->state;
    eval { $wf_persist->save };
    if ( $@ ) {
        workflow_error "Failed to create new workflow of type '", $wf->type, "': $@";
    }
    $wf->id( $wf_persist->id );
    return $wf;

}

sub save_workflow {
    my ( $self, $wf ) = @_;
    my $wf_id = $wf->id;
    my $wf_persist = eval { WorkflowPersist->fetch( $wf_id ) };
    if ( $@ ) {
        workflow_error "Failed to fetch workflow data with ID '$wf_id': $@";
    }
    $wf_persist->{state} = $wf->state;
    eval { $wf_persist->save };
    if ( $@ ) {
        workflow_error "Failed to save workflow with ID '$wf_id': $@";
    }
    return $wf;
}


sub get_workflow_history {
    my ( $self, $wf ) = @_;
    my $wf_config = $self->_get_workflow_config( $wf_type );
    my $persister = $self->_get_persister( $wf_config->{persister} );
    return $persister->fetch_history( $wf->id );
}


########################################
# ACTIONS

sub _add_action_config {
    my ( $self, @all_action_config ) = @_;
    return unless ( scalar @all_action_config );
    my $log = get_logger();
    foreach my $action_config ( @all_action_config ) {
        my $name = $action_config->{name};
        $log->debug( "Adding configuration for action '$name'" );
        $self->{_action_config}{ $name } = $action_config;
        my $action_class = $action_config->{class};
        $log->debug( "Trying to include action class '$action_class'..." );
        if ( $action_class ) {
            eval "require $action_class";
            if ( $@ ) {
                workflow_error "Cannot include action class '$action_class': $@";
            }
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
    return unless ( scalar @all_persister_config );
    my $log = get_logger();
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
        $log->debug( "Included persister '$name' class '$persister_class' ok" );
        $log->debug( "Creating instance of persister '$name'" );
        my $persister = eval { $persister_class->new( $persister_config ) };
        if ( $@ ) {
            configuration_error "Failed to create instance of persister ",
                                "'$name' of class '$persister_class': $@";
        }
        $log->debug( "Created instance of persister '$name' ok" );
        $self->{_persister}{ $name } = $persister;
    }
}

sub _get_persister {
    my ( $self, $persister_name ) = @_;
    my $persister = $self->{_persister}{ $persister_name };
    unless ( $config ) {
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
        $log->debug( "Trying to include condition class '$condition_class'" );
        if ( $condition_class ) {
            eval "require $condition_class";
            if ( $@ ) {
                workflow_error "Cannot include condition class '$condition_class': $@";
            }
            my $condition = eval { $condition_class->new( $condition_config ) };
            if ( $@ ) {
                workflow_error "Cannot create condition '$name': $@";
            }
            else {
                $self->{_conditions}{ $name } = $condition;
            }
        }
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
        $log->debug( "Trying to include validator class '$validator_class'" );
        if ( $validator_class ) {
            eval "require $validator_class";
            if ( $@ ) {
                workflow_error "Cannot include validator class '$validator_class': $@";
            }
            $log->debug( "Required validator '$name' class '$validator_class' ok" );
            my $validator = eval { $validator_class->new( $validator_config ) };
            if ( $@ ) {
                workflow_error "Cannot create validator '$name': $@";
            }
            $self->{_validators}{ $name } = $validator;
            $log->debug( "Created validator '$name' with class '$validator_class' ok" );
        }
    }
}

sub get_validator {
    my ( $self, $name ) = @_;
    unless ( $self->{_validators}{ $name } ) {
        workflow_error "No validator with name '$name' available";
    }
    return $self->{_validators}{ $name };
}

$INSTANCE = bless( {}, __PACKAGE__ );

1;

__END__

=head1 NAME

Workflow::Factory - Generates new workflow and supporting objects

=head1 SYNOPSIS

 use Workflow::Factory qw( FACTORY );

=head1 DESCRIPTION

The Workflow Factory is your primary interface to the workflow system. You give it the configuration

=head1 METHODS

=head2 Instantiation Methods

B<instance()>

The factory is a singleton, this is how you get access to the
instance. You can also just import the 'FACTORY' constant:

 use Workflow::Factory qw( FACTORY );

 FACTORY->add_config_from_file( action => 'myaction.xml' );

B<get_workflow( $workflow_type, [ $workflow_id ] )>

B<save_workflow( $workflow )>

B<get_action( $workflow, $action_name )>

B<get_condition( $condition_name )>

B<get_validator( $validator_name )>

=head2 Configuration Methods

B<add_config_from_file( %config_declarations )>

Pass in filenames for the various components you wish to initialize
using the keys 'action', 'condition', 'validator' and 'workflow'. The
value for each can be a single filename or an arrayref of
filenames.

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
'condition', 'validator' and/or 'workflow'. But the values are the
actual configuration hashrefs instead of the files holding the
configurations.

You normally will only need to call this if you are creating
configurations on the fly (e.g., hot-deploying a validator class
specified by a user) or using a custom configuration format.

B<_add_workflow_config( @config_hashrefs )>

B<_add_action_config( @config_hashrefs )>

B<_add_condition_config( @config_hashrefs )>

B<_add_validator_config( @config_hashrefs )>

=head1 SEE ALSO

L<Workflow>

L<Workflow::Action>

L<Workflow::Condition>

L<Workflow::Validator>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
