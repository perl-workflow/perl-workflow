package TestUtil;

# $Id$

use strict;
use vars qw($VERSION);
use DateTime;
use Test::More;

$VERSION = '0.01';

my ( $original_dir );

END {
    chdir( $original_dir );
}

my $LOG_FILE  = 'workflow_tests.log';
my $CONF_FILE = 'log4perl.conf';

########################################
# TICKET INFO

# Data for the initial ticket

my %TICKET = (
    current_user => 'Test User',
    creator      => 'Test User',
    subject      => 'A test ticket',
    description  => 'This is a test ticket used by the unit tests',
    type         => 'Feature',
    due_date     => DateTime->now,
);

sub get_new_ticket_info {
    return %TICKET;
}

sub set_new_ticket_context {
    my ( $class, $wf ) = @_;
    for ( keys %TICKET ) {
        $wf->context->param( $_ => $TICKET{ $_ } );
    }
}

sub check_workflow_history {
    my ( $class, $tracker, $values ) = @_;
    $class->check_tracker(
        $tracker, 'create workflow history',
        qr/^INSERT INTO workflow_history \( workflow_id, action, description, state, workflow_user, history_date, workflow_hist_id \)/,
        [ 'workflow ID', 'action', 'description',
          'state', 'user', 'current date',
          'random ID of correct length' ],
        $values );
}

sub check_tracker {
    my ( $class, $tracker, $tracker_desc, $sql_pattern, $names, $values ) = @_;
    like( $tracker->statement, $sql_pattern,
          "Statement matches ($tracker_desc)" );
    my $track_params = $tracker->bound_params;
    my $num_params = scalar @{ $names };
    is( scalar @{ $track_params }, $num_params,
        "Correct number ($num_params) of parameters bound ($tracker_desc)" );
    for ( my $i = 0; $i < $num_params; $i++ ) {
        my $this_name = ( $i == 0 )
                        ? "Bound parameter for '$names->[ $i ]' matches"
                        : "...for '$names->[ $i ]' matches";
        my @to_compare = ( ref( $values->[ $i ] ) eq 'CODE' )
                           ? $values->[ $i ]->( $track_params->[ $i ] )
                           : ( $track_params->[ $i ], $values->[ $i ] );
        is( $to_compare[0], $to_compare[1], $this_name );
    }
}

# Tests call this to initialize the workflow factory with common
# information

sub init_factory {
    require Workflow::Factory;
    my $factory = Workflow::Factory->instance;
    $factory->add_config_from_file(
        workflow  => "workflow.xml",
        action    => "workflow_action.xml",
        condition => "workflow_condition.xml",
        validator => "workflow_validator.xml"
    );
    return $factory;
}

sub init_mock_persister {
    require Workflow::Factory;
    my $factory = Workflow::Factory->instance;
    my %persister = (
        name  => 'TestPersister',
        class => 'Workflow::Persister::DBI',
        dsn   => 'DBI:Mock:',
	user => 'DBTester',
    );
    $factory->add_config( persister => [ \%persister ] );
}



# Initialize the logger and other resources; called when module
# required by test

sub init {
    if ( -f $LOG_FILE ) {
        unlink( $LOG_FILE );
    }
    elsif ( -f "t/$LOG_FILE" ) {
        unlink( "t/$LOG_FILE" );
    }

    require Cwd;
    $original_dir = Cwd::cwd();
    chdir( 't' )  if ( -d 't' );

    require Log::Log4perl;
    Log::Log4perl::init( $CONF_FILE );

}

init();

'I am true!';
