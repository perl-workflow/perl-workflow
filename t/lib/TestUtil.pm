package TestUtil;

use strict;
use vars qw($VERSION);
use DateTime;
use Log::Any::Adapter;
use Test::More;
use List::MoreUtils qw(all);

$VERSION = '0.02';


if ($ENV{DEBUG}) {
    Log::Any::Adapter->set('Stderr');
}

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
        qr/^INSERT INTO "workflow_history" \( "workflow_id", "action", "description", "state", "workflow_user", "history_date", "workflow_hist_id" \)/,
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
# information. This tests the xml config files.

sub init_factory {
    require Workflow::Factory;
    my $factory = Workflow::Factory->instance;
    $factory->add_config_from_file(
        workflow  => [
            't/workflow.d/workflow.xml',
            't/workflow.d/workflow_evaluate_condition.xml',
            't/workflow_type.d/workflow_type.xml'
        ],
        action    => [
            't/workflow.d/workflow_action.xml',
            't/workflow_type.d/workflow_action_type.xml'
        ],
        condition => [
            't/workflow.d/workflow_condition.xml',
            't/workflow_type.d/workflow_condition_type.xml'
        ],
        validator => "t/workflow.d/workflow_validator.xml"
    );
    return $factory;
}

# Initialize with perl config files.

sub init_factory_perl_config {
    require Workflow::Factory;
    my $factory = Workflow::Factory->instance;
    $factory->add_config_from_file(
        workflow  => [
            't/workflow.d/workflow.perl',
            't/workflow_type.d/workflow_type.perl'
        ],
        action    => [
            't/workflow.d/workflow_action.perl',
            't/workflow_type.d/workflow_action_type.perl'
        ],
        condition => [
            't/workflow.d/workflow_condition.perl',
            't/workflow_type.d/workflow_condition_type.perl'
        ],
        validator => 't/workflow.d/workflow_validator.perl'
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
        date_format => '%Y-%m-%dT%H:%M:%S',
        user => 'DBTester',
    );
    $factory->add_config( persister => [ \%persister ] );
}



# Used with state tests with various configs.
sub run_state_tests{
  my $factory = shift;

  # Call Type2 first. It gets loaded second, so this
  # should verify that both types are available.
  my $wf2 = $factory->create_workflow( 'Type2' );

  my $wf_state = $wf2->_get_workflow_state();
  is( $wf_state->state(), 'INITIAL', 'In INITIAL state.');

  my @actions = $wf_state->get_available_action_names( $wf2 );
  is( (scalar @actions), 1, 'Got back one available action.');
  is( $actions[0], 'TIX_NEW', 'Got TIX_NEW as available action.');

  # Verify the correct action and class.
  my $wf_action = $wf2->get_action('TIX_NEW');
  is( $wf_action->name(), 'TIX_NEW', 'Got TIX_NEW action for Type2.');
  is( $wf_action->class(), 'TestApp::Action::TicketCreateType',
      'Got TicketCreateType class.');

  TestUtil->set_new_ticket_context( $wf2 );
  ok( $wf2->execute_action('TIX_NEW'), 'Ran TIX_NEW action.');

  $wf_state = $wf2->_get_workflow_state();
  is( $wf_state->state(), 'Ticket_Created', 'In Ticket_Created state.');

  @actions = $wf_state->get_available_action_names( $wf2 );
  is( (scalar @actions), 1, 'Got back one available action.');
  is( $actions[0], 'Ticket_Close', 'Got Ticket_Close as available action.');

  # Repeat on the Ticket workflow where the actions have no type.

  my $wf = $factory->create_workflow( 'Ticket' );

  $wf_state = $wf->_get_workflow_state();
  is( $wf_state->state(), 'INITIAL', 'In INITIAL state for Ticket type.');

  @actions = $wf_state->get_available_action_names( $wf );
  is( (scalar @actions), 1, 'Got back one available action.');
  is( $actions[0], 'TIX_NEW', 'Got TIX_NEW as available action.');

  # Verify the correct action and class.
  $wf_action = $wf->get_action('TIX_NEW');
  is( $wf_action->name(), 'TIX_NEW', 'Got TIX_NEW action for Ticket.');
  is( $wf_action->class(), 'TestApp::Action::TicketCreate',
      'Got TicketCreate class.');

  TestUtil->set_new_ticket_context( $wf );
  ok( $wf->execute_action('TIX_NEW'), 'Ran TIX_NEW action.');

  $wf_state = $wf->_get_workflow_state();
  is( $wf_state->state(), 'TIX_CREATED', 'In TIX_CREATED state.');

  @actions = $wf_state->get_available_action_names( $wf2 );
  is( (scalar @actions), 2, 'Got back two available actions.');
  ok(all { defined $_ } qw(TIX_EDIT TIX_COMMENT), 'Got TIX_EDIT and TIX_COMMENT as available actions.');

  $wf_action = $wf->get_action( 'TIX_COMMENT' );
  is( $wf_action->index, 42, 'Got config specified in State' );
}

'I am true!';
