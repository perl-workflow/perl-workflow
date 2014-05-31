package Workflow::Factory;

# $Id$

use warnings;
use strict;
use base qw( Workflow::Base );
use DateTime;
use Log::Log4perl qw( get_logger );
use Workflow::Exception qw( configuration_error workflow_error );
use Carp qw(croak);
use English qw( -no_match_vars );
$Workflow::Factory::VERSION = '1.22';

# Extra action attribute validation is off by default for compatibility.
our $VALIDATE_ACTION_CONFIG = 0;

my ($log);
my (%INSTANCES);

## no critic (Subroutines::RequireArgUnpacking)
sub import {
    my $class = shift;
    $log ||= get_logger();

    $class = ref $class || $class;    # just in case
    my $package = caller;

    if ( defined $_[0] && $_[0] eq 'FACTORY' ) {
        $log->is_debug
            && $log->debug(
            "Trying to import 'FACTORY' of type '$class' to '$package'");
        shift;
        my $instance = _initialize_instance($class);

        my $import_target = $package . '::FACTORY';
        no strict 'refs';
        unless ( defined &{$import_target} ) {
            $log->is_debug
                && $log->debug( "Target '$import_target' not yet defined, ",
                "creating subroutine on the fly" );
            *{$import_target} = sub { return $instance };
        }
        return $instance;
    }
    $class->SUPER::import(@_);
}

require Workflow;
require Workflow::Action;
require Workflow::Condition;
require Workflow::Config;
require Workflow::Context;
require Workflow::History;
require Workflow::Persister;
require Workflow::State;
require Workflow::Validator;

my $DEFAULT_INITIAL_STATE = 'INITIAL';

my @FIELDS = qw(config_callback);

__PACKAGE__->mk_accessors(@FIELDS);

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    workflow_error "Please call 'instance()' or import the 'FACTORY' object ",
        "to get the '$class' object rather than instantiating a ",
        "new one directly.";
}

sub instance {
    my $proto = shift;
    my $class = ref $proto || $proto;

    return _initialize_instance($class);
}

sub _initialize_instance {
    my ($class) = @_;
    $log ||= get_logger();

    unless ( $INSTANCES{$class} ) {
        $log->is_debug
            && $log->debug(
            "Creating empty instance of '$class' factory for ",
            "singleton use" );
        $INSTANCES{$class} = bless {} => $class;
    }
    return $INSTANCES{$class};
}

sub _delete_instance {
    my ($class) = @_;
    $log ||= get_logger();

    if ( $INSTANCES{$class} ) {
        $log->is_debug
            && $log->debug("Deleting instance of '$class' factory.");
        delete $INSTANCES{$class};
    } else {
        $log->is_debug
            && $log->debug("No instance of '$class' factory found.");
    }

    return;
}

my %CONFIG = ( 'Workflow::Config' => 1 );

sub add_config_from_file {
    my ( $self, %params ) = @_;
    return unless ( scalar keys %params );

    $log ||= get_logger();

    _check_config_keys(%params);

    foreach my $type ( sort keys %params ) {
        $log->is_debug
            && $log->debug( "Using '$type' configuration file(s): ",
            join ', ', _flatten( $params{$type} ) );
    }

    $log->is_debug
        && $log->debug("Adding condition configurations...");

    if ( ref $params{condition} eq 'ARRAY' ) {
        foreach my $condition ( @{ $params{condition} } ) {
            $self->_add_condition_config(
                Workflow::Config->parse_all_files( 'condition', $condition )
            );
        }
    } else {
        $self->_add_condition_config(
            Workflow::Config->parse_all_files(
                'condition', $params{condition}
            )
        );
    }

    $log->is_debug
        && $log->debug("Adding validator configurations...");

    if ( ref $params{validator} eq 'ARRAY' ) {
        foreach my $validator ( @{ $params{validator} } ) {
            $self->_add_validator_config(
                Workflow::Config->parse_all_files( 'validator', $validator )
            );
        }
    } else {
        $self->_add_validator_config(
            Workflow::Config->parse_all_files(
                'validator', $params{validator}
            )
        );
    }

    $log->is_debug
        && $log->debug("Adding persister configurations...");

    if ( ref $params{persister} eq 'ARRAY' ) {
        foreach my $persister ( @{ $params{persister} } ) {
            $self->_add_persister_config(
                Workflow::Config->parse_all_files( 'persister', $persister )
            );
        }
    } else {
        $self->_add_persister_config(
            Workflow::Config->parse_all_files(
                'persister', $params{persister}
            )
        );
    }

    $log->is_debug
        && $log->debug("Adding action configurations...");

    if ( ref $params{action} eq 'ARRAY' ) {
        foreach my $action ( @{ $params{action} } ) {
            $self->_add_action_config(
                Workflow::Config->parse_all_files( 'action', $action ) );
        }
    } else {
        $self->_add_action_config(
            Workflow::Config->parse_all_files( 'action', $params{action} ) );
    }

    $log->is_debug
        && $log->debug("Adding workflow configurations...");

    if ( ref $params{workflow} eq 'ARRAY' ) {
        foreach my $workflow ( @{ $params{workflow} } ) {
            $self->_add_workflow_config(
                Workflow::Config->parse_all_files( 'workflow', $workflow ) );
        }
    } else {
        $self->_add_workflow_config(
            Workflow::Config->parse_all_files(
                'workflow', $params{workflow}
            )
        );
    }

    return;
}

sub add_config {
    my ( $self, %params ) = @_;
    return unless ( scalar keys %params );
    _check_config_keys(%params);
    $self->_add_condition_config( _flatten( $params{condition} ) );
    $self->_add_validator_config( _flatten( $params{validator} ) );
    $self->_add_persister_config( _flatten( $params{persister} ) );
    $self->_add_action_config( _flatten( $params{action} ) );
    $self->_add_workflow_config( _flatten( $params{workflow} ) );
    return;
}

sub _check_config_keys {
    my (%params) = @_;
    my @bad_keys
        = grep { !Workflow::Config->is_valid_config_type($_) } keys %params;
    if ( scalar @bad_keys ) {
        workflow_error "You tried to add configuration information to the ",
            "workflow factory with one or more bad keys: ",
            join( ', ', @bad_keys ), ". The following are the ",
            "keys you have to choose from: ",
            join( ', ', Workflow::Config->get_valid_config_types ), '.';
    }
}

sub _flatten {
    my ($item) = @_;
    return ( ref $item eq 'ARRAY' ) ? @{$item} : ($item);
}

########################################
# WORKFLOW

sub _add_workflow_config {
    my ( $self, @all_workflow_config ) = @_;
    return unless ( scalar @all_workflow_config );
    $log ||= get_logger();

    foreach my $workflow_config (@all_workflow_config) {
        next unless ( ref $workflow_config eq 'HASH' );
        my $wf_type = $workflow_config->{type};
        $self->{_workflow_config}{$wf_type} = $workflow_config;

        # Create Workflow::State objects for each configured state.
        # When we instantiate a new workflow we pass these objects

        foreach my $state_conf ( @{ $workflow_config->{state} } ) {

            # Add the workflow type to the state conf.
            $state_conf->{type} = $wf_type;
            my $wf_state = Workflow::State->new( $state_conf, $self );

            push @{ $self->{_workflow_state}{$wf_type} }, $wf_state;
        }

        $log->is_info
            && $log->info("Added all workflow states...");

        $self->_load_observers($workflow_config);
        $log->is_info
            && $log->info("Added all workflow observers...");
    }
}

# Load all the observers so they're available when we instantiate the
# workflow

sub _load_observers {
    my ( $self, $workflow_config ) = @_;
    my $wf_type        = $workflow_config->{type};
    my $observer_specs = $workflow_config->{observer} || [];
    my @observers      = ();
    foreach my $observer_info ( @{$observer_specs} ) {
        if ( my $observer_class = $observer_info->{class} ) {
            $self->_load_class( $observer_class,
                      "Cannot require observer '%s' to watch observer "
                    . "of type '$wf_type': %s" );
            push @observers, $observer_class;
        } elsif ( my $observer_sub = $observer_info->{sub} ) {
            my ( $observer_class, $observer_sub )
                = $observer_sub =~ /^(.*)::(.*)$/;
            $self->_load_class( $observer_class,
                "Cannot require observer '%s' with sub '$observer_sub' to "
                    . "watch observer of type '$wf_type': %s" );
            my $o_sub_name = $observer_class . '::' . $observer_sub;
            if (exists &$o_sub_name) {
                no strict 'refs';
                push @observers, \&{ $o_sub_name };
            } else {
                my $error = 'subroutine not found';
                $log->error( "Error loading subroutine '$observer_sub' in ",
                    "class '$observer_class': $error" );
                workflow_error $error;
            }
        } else {
            workflow_error "Cannot add observer to '$wf_type': you must ",
                "have either 'class' or 'sub' defined. (See ",
                "Workflow::Factory docs for details.)";
        }
    }
    $log->is_info
        && $log->info( "Added observers to '$wf_type': ", join ', ',
        @observers );
    $self->{_workflow_observers}{$wf_type}
        = scalar @observers ? \@observers : undef;
}

sub _load_class {
    my ( $self, $class_to_load, $msg ) = @_;
    eval "require $class_to_load";
    if ($EVAL_ERROR) {
        my $full_msg = sprintf $msg, $class_to_load, $EVAL_ERROR;
        $log->error($full_msg);
        workflow_error $full_msg;
    }

}

sub create_workflow {
    my ( $self, $wf_type, $context, $wf_class ) = @_;
    $log ||= get_logger();

    $wf_class = 'Workflow' unless ($wf_class);

    my $wf_config = $self->_get_workflow_config($wf_type);
    unless ($wf_config) {
        workflow_error "No workflow of type '$wf_type' available";
    }

    my $wf
        = $wf_class->new( undef,
        $wf_config->{initial_state} || $DEFAULT_INITIAL_STATE,
        $wf_config, $self->{_workflow_state}{$wf_type}, $self );
    $wf->context( $context || Workflow::Context->new );
    $wf->last_update( DateTime->now( time_zone => $wf->time_zone() ) );
    $log->is_info
        && $log->info("Instantiated workflow object properly, persisting...");
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $id        = $persister->create_workflow($wf);
    $wf->id($id);
    $log->is_info
        && $log->info(
        "Persisted workflow with ID '$id'; creating history...");
    $persister->create_history(
        $wf,
        Workflow::History->new(
            {   workflow_id => $id,
                action      => $persister->get_create_action($wf),
                description => $persister->get_create_description($wf),
                user        => $persister->get_create_user($wf),
                state       => $wf->state,
                date        => DateTime->now( time_zone => $wf->time_zone() ),
                time_zone   => $wf->time_zone(),
            }
        )
    );
    $log->is_info && $log->info("Created history object ok");

    $self->_commit_transaction($wf);

    my $state = $wf->_get_workflow_state();
    if ( $state->autorun ) {
        $log->is_info && $log->info( "State '$state' marked to be run ",
            "automatically; executing that state/action..." );
        $wf->_auto_execute_state($state);
    }

    $self->associate_observers_with_workflow($wf);
    $wf->notify_observers('create');

    return $wf;
}

sub fetch_workflow {
    my ( $self, $wf_type, $wf_id, $context, $wf_class ) = @_;
    $log ||= get_logger();

    $wf_class = 'Workflow' unless ($wf_class);

    my $wf_config = $self->_get_workflow_config($wf_type);
    unless ($wf_config) {
        workflow_error "No workflow of type '$wf_type' available";
    }
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $wf_info   = $persister->fetch_workflow($wf_id);
    return undef unless ($wf_info);
    $wf_info->{last_update} ||= '';
    $log->is_debug
        && $log->debug(
        "Fetched data for workflow '$wf_id' ok: ",
        "[State: $wf_info->{state}] ",
        "[Last update: $wf_info->{last_update}]"
        );
    my $wf = $wf_class->new( $wf_id, $wf_info->{state}, $wf_config,
        $self->{_workflow_state}{$wf_type}, $self );

    $wf->context( $wf_info->{context} || Workflow::Context->new ); #if ( not $wf->context() );
    $wf->last_update( $wf_info->{last_update} );

    $persister->fetch_extra_workflow_data($wf);

    $self->associate_observers_with_workflow($wf);
    $wf->notify_observers('fetch');

    return $wf;
}

sub associate_observers_with_workflow {
    my ( $self, $wf ) = @_;
    my $observers = $self->{_workflow_observers}{ $wf->type };
    return unless ( ref $observers eq 'ARRAY' );
    $wf->add_observer($_) for ( @{$observers} );
}

sub _initialize_workflow_config {
    my $self    = shift;
    my $wf_type = shift;
    $log ||= get_logger();
    if ( ref( $self->config_callback ) eq 'CODE' ) {
        my $args = &{ $self->config_callback }($wf_type);
        $self->add_config_from_file( %{$args} ) if $args && %{$args};
    }
}

sub _get_workflow_config {
    my ( $self, $wf_type ) = @_;
    $self->_initialize_workflow_config($wf_type)
        unless $self->{_workflow_config}{$wf_type};
    return $self->{_workflow_config}{$wf_type};
}

sub _insert_workflow {
    my ( $self, $wf ) = @_;
    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    my $id        = $persister->create_workflow($wf);
    $wf->id($id);
    return $wf;

}

sub save_workflow {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();

    my $old_update = $wf->last_update;
    $wf->last_update( DateTime->now( time_zone => $wf->time_zone() ) );

    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    eval {
        $persister->update_workflow($wf);
        $log->is_info
            && $log->info( "Workflow '", $wf->id, "' updated ok" );
        my @unsaved = $wf->get_unsaved_history;
        foreach my $h (@unsaved) {
            $h->set_new_state( $wf->state );
        }
        $persister->create_history( $wf, @unsaved );
        $log->is_info
            && $log->info("Created necessary history objects ok");
    };
    if ($EVAL_ERROR) {
        $wf->last_update($old_update);
        croak $EVAL_ERROR;
    }

    $wf->notify_observers('save');

    return $wf;
}

# Only implemented for DBI. Don't know if this could be implemented
# for other persisters.
sub _commit_transaction {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();
    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    $persister->commit_transaction();
    $log->debug('Committed transaction.');
    return;
}

sub _rollback_transaction {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();
    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    $persister->rollback_transaction();
    $log->debug('Rolled back transaction.');
    return;
}

sub get_workflow_history {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();
    $log->is_debug
        && $log->debug( "Trying to fetch history for workflow ", $wf->id );
    my $wf_config = $self->_get_workflow_config( $wf->type );
    my $persister = $self->get_persister( $wf_config->{persister} );
    return $persister->fetch_history($wf);
}

########################################
# ACTIONS

sub _add_action_config {
    my ( $self, @all_action_config ) = @_;
    $log ||= get_logger();
    return unless ( scalar @all_action_config );

    foreach my $actions (@all_action_config) {
        next unless ( ref $actions eq 'HASH' );

        # TODO Handle optional type.
        # Should we check here to see if this matches an existing
        # workflow type? Maybe do a type check at the end of the config
        # process?
        my $type = exists $actions->{type} ? $actions->{type} : 'default';

        my $action;
        if ( exists $actions->{action} ) {
            $action = $actions->{action};
        } else {
            push @{$action}, $actions;
        }

        foreach my $action_config ( @{$action} ) {
            my $name = $action_config->{name};
            $log->is_debug
                && $log->debug(
                "Adding configuration for type '$type', action '$name'");
            $self->{_action_config}{$type}{$name} = $action_config;
            my $action_class = $action_config->{class};
            unless ($action_class) {
                configuration_error
                    "Action '$name' must be associated with a ",
                    "class using the 'class' attribute.";
            }
            $log->is_debug
                && $log->debug(
                "Trying to include action class '$action_class'...");
            eval "require $action_class";
            if ($EVAL_ERROR) {
                configuration_error
                    "Cannot include action class '$action_class': $EVAL_ERROR";
            }
            $log->is_debug
                && $log->debug(
                "Included action '$name' class '$action_class' ok");
	    if ($self->_validate_action_config) {
		my $validate_name = $action_class . '::validate_config';
		if (exists &$validate_name) {
		    no strict 'refs';
		    $log->is_debug
			&& $log->debug(
			"Validating configuration for action '$name'");
		    $validate_name->($action_config);
		}
	    }
        }    # End action for.
    }
}

sub get_action {
    my ( $self, $wf, $action_name ) = @_;
    my $config;

    # Check for a specific action type.
    $config = $self->{_action_config}{ $wf->type }{$action_name};

    # Check for a default if no type is available.
    $config = $self->{_action_config}{default}{$action_name}
        if not keys %{$config};

    unless ($config) {
        workflow_error "No action with name '$action_name' available";
    }

    my $action_class = $config->{class};
    return $action_class->new( $wf, $config );
}

########################################
# PERSISTERS

sub _add_persister_config {
    my ( $self, @all_persister_config ) = @_;
    $log ||= get_logger();
    return unless ( scalar @all_persister_config );

    foreach my $persister_config (@all_persister_config) {
        next unless ( ref $persister_config eq 'HASH' );
        my $name = $persister_config->{name};
        $log->is_debug
            && $log->debug("Adding configuration for persister '$name'");
        $self->{_persister_config}{$name} = $persister_config;
        my $persister_class = $persister_config->{class};
        unless ($persister_class) {
            configuration_error "You must specify a 'class' in persister ",
                "'$name' configuration";
        }
        $log->is_debug
            && $log->debug(
            "Trying to include persister class '$persister_class'...");
        eval "require $persister_class";
        if ($EVAL_ERROR) {
            configuration_error "Cannot include persister class ",
                "'$persister_class': $EVAL_ERROR";
        }
        $log->is_debug
            && $log->debug(
            "Included persister '$name' class '$persister_class' ",
            "ok; now try to instantiate persister..." );
        my $persister = eval { $persister_class->new($persister_config) };
        if ($EVAL_ERROR) {
            configuration_error "Failed to create instance of persister ",
                "'$name' of class '$persister_class': $EVAL_ERROR";
        }
        $self->{_persister}{$name} = $persister;
        $log->is_debug
            && $log->debug("Instantiated persister '$name' ok");
    }
}

sub get_persister {
    my ( $self, $persister_name ) = @_;
    my $persister = $self->{_persister}{$persister_name};
    unless ($persister) {
        workflow_error "No persister with name '$persister_name' available";
    }
    return $persister;
}

sub get_persisters {
    my $self       = shift;
    my @persisters = sort keys %{ $self->{_persister} };

    return @persisters;
}

sub get_persister_for_workflow_type {
    my $self = shift;

    my ($type) = @_;
    my $wf_config = $self->_get_workflow_config($type);
    if ( not $wf_config ) {
        workflow_error "no workflow of type '$type' available";
    }
    my $persister = $self->get_persister( $wf_config->{'persister'} );

    return $persister;
}

########################################
# CONDITIONS

sub _add_condition_config {
    my ( $self, @all_condition_config ) = @_;
    $log ||= get_logger();

    return unless ( scalar @all_condition_config );

    foreach my $conditions (@all_condition_config) {
        next unless ( ref $conditions eq 'HASH' );

        my $type
            = exists $conditions->{type} ? $conditions->{type} : 'default';

        my $c;
        if ( exists $conditions->{condition} ) {
            $c = $conditions->{condition};
        } else {
            push @{$c}, $conditions;
        }

        foreach my $condition_config ( @{$c} ) {
            my $name = $condition_config->{name};
            $log->is_debug
                && $log->debug("Adding configuration for condition '$name'");
            $self->{_condition_config}{$type}{$name} = $condition_config;
            my $condition_class = $condition_config->{class};
            unless ($condition_class) {
                configuration_error "Condition '$name' must be associated ",
                    "with a class using the 'class' attribute";
            }
            $log->is_debug
                && $log->debug(
                "Trying to include condition class '$condition_class'");
            eval "require $condition_class";
            if ($EVAL_ERROR) {
                configuration_error "Cannot include condition class ",
                    "'$condition_class': $EVAL_ERROR";
            }
            $log->is_debug
                && $log->debug(
                "Included condition '$name' class '$condition_class' ",
                "ok; now try to instantiate condition..." );
            my $condition = eval { $condition_class->new($condition_config) };
            if ($EVAL_ERROR) {
                configuration_error
                    "Cannot create condition '$name': $EVAL_ERROR";
            }
            $self->{_conditions}{$type}{$name} = $condition;
            $log->is_debug
                && $log->debug("Instantiated condition '$name' ok");
        }
    }
}

sub get_condition {
    my ( $self, $name, $type ) = @_;

    my $condition;

    if ( defined $type ) {
        $condition = $self->{_conditions}{$type}{$name};
    }

    # This catches cases where type isn't defined and cases
    # where the condition was defined as the default rather than
    # the current Workflow type.
    if ( not defined $condition ) {
        $condition = $self->{_conditions}{'default'}{$name};
    }

    unless ($condition) {
        workflow_error "No condition with name '$name' available";
    }
    return $condition;
}

########################################
# VALIDATORS

sub _add_validator_config {
    my ( $self, @all_validator_config ) = @_;
    $log ||= get_logger();
    return unless (@all_validator_config);

    foreach my $validators (@all_validator_config) {
        next unless ( ref $validators eq 'HASH' );

        my $v;
        if ( exists $validators->{validator} ) {
            $v = $validators->{validator};
        } else {
            push @{$v}, $validators;
        }

        for my $validator_config ( @{$v} ) {
            my $name = $validator_config->{name};
            $log->is_debug
                && $log->debug("Adding configuration for validator '$name'");
            $self->{_validator_config}{$name} = $validator_config;
            my $validator_class = $validator_config->{class};
            unless ($validator_class) {
                configuration_error
                    "Validator '$name' must be associated with ",
                    "a class using the 'class' attribute.";
            }
            $log->is_debug
                && $log->debug(
                "Trying to include validator class '$validator_class'");
            eval "require $validator_class";
            if ($EVAL_ERROR) {
                workflow_error
                    "Cannot include validator class '$validator_class': $EVAL_ERROR";
            }
            $log->is_debug
                && $log->debug(
                "Included validator '$name' class '$validator_class' ",
                " ok; now try to instantiate validator..."
                );
            my $validator = eval { $validator_class->new($validator_config) };
            if ($EVAL_ERROR) {
                workflow_error "Cannot create validator '$name': $EVAL_ERROR";
            }
            $self->{_validators}{$name} = $validator;
            $log->is_debug
                && $log->debug("Instantiated validator '$name' ok");
        }
    }
}

sub get_validator {
    my ( $self, $name ) = @_;
    unless ( $self->{_validators}{$name} ) {
        workflow_error "No validator with name '$name' available";
    }
    return $self->{_validators}{$name};
}

sub get_validators {
    my $self       = shift;
    my @validators = sort keys %{ $self->{_validators} };
    return @validators;
}

1;

sub _validate_action_config {
    return $VALIDATE_ACTION_CONFIG;
}

__END__


=head1 NAME

Workflow::Factory - Generates new workflow and supporting objects

=head1 VERSION

This documentation describes version 1.18 of this package

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

=head3 instance()

The factory is a singleton, this is how you get access to the
instance. You can also just import the 'FACTORY' constant as in the
L</SYNOPSIS>.

=head3 create_workflow( $workflow_type, $context, $wf_class )

Create a new workflow of type C<$workflow_type>. This will create a
new record in whatever persistence mechanism you have associated with
C<$workflow_type> and set the workflow to its initial state.

The C<$context> argument is optional, you can pass an exisiting instance 
of Workflow::Context to be reused. Otherwise a new instance is created.

The C<$wf_class> argument is optional. Pass it the name of a class to be
used for the workflow to be created. By default, all workflows are of the 
I<Workflow> class.

Any observers you've associated with this workflow type will be
attached to the returned workflow object.

This fires a 'create' event from the just-created workflow object. See
C<WORKFLOWS ARE OBSERVABLE> in L<Workflow> for more.

Returns: newly created workflow object.

=head3 fetch_workflow( $workflow_type, $workflow_id, $context, $wf_class )

Retrieve a workflow object of type C<$workflow_type> and ID
C<$workflow_id>. (The C<$workflow_type> is necessary so we can fetch
the workflow using the correct persister.) If a workflow with ID
C<$workflow_id> is not found C<undef> is returned.

The C<$context> argument is optional, you can pass an exisiting instance 
of Workflow::Context to be reused. Otherwise a new instance is created.

The C<$wf_class> argument is optional. Pass it the name of a class to be
used for the workflow to be created. By default, all workflows are of the 
I<Workflow> class.

Any observers you've associated with this workflow type will be
attached to the returned workflow object.

This fires a 'fetch' event from the retrieved workflow object. See
C<WORKFLOWS ARE OBSERVABLE> in L<Workflow> for more.

Throws exception if no workflow type C<$workflow_type> available.

Returns: L<Workflow> object

=head3 add_config_from_file( %config_declarations )

Pass in filenames for the various components you wish to initialize
using the keys 'action', 'condition', 'persister', 'validator' and
'workflow'. The value for each can be a single filename or an arrayref
of filenames.

The system is familiar with the 'perl' and 'xml' configuration formats
-- see the 'doc/configuration.txt' for what we expect as the format
and will autodetect the types based on the file extension of each
file. Just give your file the right extension and it will be read in
properly.

You may also use your own custom configuration file format -- see
C<SUBCLASSING> in L<Workflow::Config> for what you need to do.

You can also read it in yourself and add the resulting hash reference
directly to the factory using C<add_config()>. However, you need to
ensure the configurations are added in the proper order -- when you
add an 'action' configuration and reference 'validator' objects, those
objects should already be read in. A good order is: 'validator',
'condition', 'action', 'workflow'. Then just pass the resulting hash
references to C<add_config()> using the right type and the behavior
should be exactly the same.

Returns: nothing; if we run into a problem parsing one of the files or
creating the objects it requires we throw a L<Workflow::Exception>.

=head3 add_config( %config_hashrefs )

Similar to C<add_config_from_file()> -- the keys may be 'action',
'condition', 'persister', 'validator' and/or 'workflow'. But the
values are the actual configuration hashrefs instead of the files
holding the configurations.

You normally will only need to call this if you are programmatically
creating configurations (e.g., hot-deploying a validator class
specified by a user) or using a custom configuration format and for
some reason do not want to use the built-in mechanism in
L<Workflow::Config> to read it for you.

Returns: nothing; if we encounter an error trying to create the
objects referenced in a configuration we throw a
L<Workflow::Exception>.

=head3 get_persister_for_workflow_type

=head3 get_persisters

#TODO

=head3 get_validators

#TODO

=head2 Internal Methods

#TODO

=head3 save_workflow( $workflow )

Stores the state and current datetime of the C<$workflow> object. This
is normally called only from the L<Workflow> C<execute_action()>
method.

This method respects transactions if the selected persister supports it.
Currently, the DBI-based persisters will commit the workflow transaction
if everything executes successfully and roll back if something fails.
Note that you need to manage any L<Workflow::Persister::DBI::ExtraData>
transactions yourself.

Returns: C<$workflow>

=head3 get_workflow_history( $workflow )

Retrieves all L<Workflow::History> objects related to C<$workflow>.

B<NOTE>: Normal users get the history objects from the L<Workflow>
object itself. Under the covers it calls this.

Returns: list of L<Workflow::History> objects

=head3 get_action( $workflow, $action_name )

Retrieves the action C<$action_name> from workflow C<$workflow>. Note
that this does not do any checking as to whether the action is proper
given the state of C<$workflow> or anything like that. It is mostly an
internal method for L<Workflow> (which B<does> do checking as to the
propriety of the action) to instantiate new actions.

Throws exception if no action with name C<$action_name> available.

Returns: L<Workflow::Action> object

=head3 get_persister( $persister_name )

Retrieves the persister with name C<$persister_name>.

Throws exception if no persister with name C<$persister_name>
available.

=head3 get_condition( $condition_name )

Retrieves the condition with name C<$condition_name>.

Throws exception if no condition with name C<$condition_name>
available.

=head3 get_validator( $validator_name )

Retrieves the validator with name C<$validator_name>.

Throws exception if no validator with name C<$validator_name>
available.

=head2 Internal Configuration Methods

=head3 _add_workflow_config( @config_hashrefs )

Adds all configurations in C<@config_hashrefs> to the factory. Also
cycles through the workflow states and creates a L<Workflow::State>
object for each. These states are passed to the workflow when it is
instantiated.

We also require any necessary observer classes and throw an exception
if we cannot. If successful the observers are kept around and attached
to a workflow in L</create_workflow()> and L</fetch_workflow()>.

Returns: nothing

=head3 _add_action_config( @config_hashrefs )

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
action.

Throws an exception if there is no 'class' associated with an action
or if we cannot 'require' that class.

Returns: nothing

=head3 _add_persister_config( @config_hashrefs )

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
persister.

Throws an exception if there is no 'class' associated with a
persister, if we cannot 'require' that class, or if we cannot
instantiate an object of that class.

Returns: nothing

=head3 _add_condition_config( @config_hashrefs )

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
condition.

Throws an exception if there is no 'class' associated with a
condition, if we cannot 'require' that class, or if we cannot
instantiate an object of that class.

Returns: nothing

=head3 _add_validator_config( @config_hashrefs )

Adds all configurations in C<@config_hashrefs> to the factory, doing a
'require' on the class referenced in the 'class' attribute of each
validator.

Throws an exception if there is no 'class' associated with a
validator, if we cannot 'require' that class, or if we cannot
instantiate an object of that class.

Returns: nothing

=head3 _commit_transaction

Calls the commit method in the workflow's persister.

Returns: nothing

=head3 _rollback_transaction

Calls the rollback method in the workflow's persister.

=head3 associate_observers_with_workflow

Add defined observers with workflow.

The workflow has to be provided as the single parameter accepted by this
method.

The observers added will have to be of the type relevant to the workflow type.

=head3 new

The new method is a dummy constructor, since we are using a factory it makes
no sense to call new - and calling new will result in a L<Workflow::Exception>

L</instance> should be called or the imported 'FACTORY' should be utilized.

=head1 DYNAMIC CONFIG LOADING

If you have either a large set of config files or a set of very large
config files then you may not want to incur the overhead of loading
each and every one on startup if you cannot predict which set you will
use in that instance of your application.

This approach doesn't make much sense in a persistent environment such
as mod_perl but it may lower startup costs if you have regularly
scheduled scripts that may not need to touch all possible types of
workflow.

To do this you can specify a callback that the factory will use to
retrieve batched hashes of config declarations. Whenever an unknown
workflow name is encountered the factory will first try to load your
config declarations then continue.

The callback takes one argument which is the workflow type. It should
return a reference to a hash of arguments in a form suitable for
C<add_config_from_file>.

For example:

 use Workflow::Factory qw(FACTORY);
 use My::Config::System;

 sub init {
   my $self = shift;

   FACTORY->config_callback(
     sub {
       my $wf_type = shift;
       my %ret = My::Config::System->get_files_for_wf( $wf_type ) || ();
       return \%ret;
     }
   );
 }

=head1 SUBCLASSING

=head2 Implementation and Usage

You can subclass the factory to implement your own methods and still
use the useful facade of the C<FACTORY> constant. For instance, the
implementation is typical Perl subclassing:

 package My::Cool::Factory;
 
 use strict;
 use base qw( Workflow::Factory );
 
 sub some_cool_method {
     my ( $self ) = @_;
     ...
 }

To use your factory you can just do the typical import:

 #!/usr/bin/perl
 
 use strict;
 use My::Cool::Factory qw( FACTORY );

Or you can call C<instance()> directly:

 #!/usr/bin/perl
 
 use strict;
 use My::Cool::Factory;
 
 my $factory = My::Cool::Factory->instance();

=head1 GLOBAL RUN-TIME OPTIONS

Setting package variable B<$VALIDATE_ACTION_CONFIG> to a true value (it
is undef by default) turns on optional validation of extra attributes
of L<Workflow::Action> configs.  See L<Workflow::Action> for details.

=head1 SEE ALSO

L<Workflow>

L<Workflow::Action>

L<Workflow::Condition>

L<Workflow::Config>

L<Workflow::Persister>

L<Workflow::Validator>

=head1 COPYRIGHT

Copyright (c) 2003-2010 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt> is the current maintainer.

Chris Winters E <lt> chris @cwinters . comE <gt>, original author .

=cut
