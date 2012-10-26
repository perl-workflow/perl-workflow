# --perl--
#
# vim: syntax=perl

use strict;
use warnings;

use Test::More;

require Workflow::Factory;
require Workflow::Persister::DBI;

my $debug = $ENV{TEST_DEBUG};

# base name used to find config files
my $cfgbase = $0;
$cfgbase =~ s/\.t$/.d/;

my $LOG_FILE  = 'workflow_tests.log';
my $CONF_FILE = 'log4perl.conf';

require Log::Log4perl;
if ($debug) {
    if ( -f $LOG_FILE ) {
        unlink($LOG_FILE);
    }
    Log::Log4perl::init($CONF_FILE);
}

plan tests => 8;

my $workflow_conf  = $cfgbase . '/workflow_def_wfnest.xml';
my $action_conf    = $cfgbase . '/workflow_activity_wfnest.xml';
my $condition_conf = $cfgbase . '/workflow_condition_wfnest.xml';
my $validator_conf = $cfgbase . '/workflow_validator_wfnest.xml';

my $factory = Workflow::Factory->instance;

my @persisters = (
    {   name  => 'TestWFNest',
        class => 'Workflow::Persister::DBI',
        dsn   => 'DBI:Mock:',
        user  => 'DBTester',
    }
);

diag("add mock persister") if $debug;
$factory->add_config( persister => \@persisters, );

diag("add workflow, action, condition") if $debug;
$factory->add_config_from_file(
    workflow  => $workflow_conf,
    action    => $action_conf,
    condition => $condition_conf,
);

# Instantiate a new workflow...
my $workflow = $factory->create_workflow('WFNEST');

#print "Workflow ", $workflow->id, " ", "currently at state ", $workflow->state, "\n";
is( $workflow->state, 'INITIAL', 'initial workflow state' );

# Display available actions...
#print "Available actions: ", $workflow->get_current_actions, "\n";
$workflow->execute_action('initialize');
is( $workflow->state, 'INITIALIZED', 'initialized state' );

##################################################
# RUN TESTS ON 'Greedy_OR'
##################################################

#diag( "Available actions: " . join(', ', $workflow->get_current_actions));
$workflow->execute_action('test_greedy_or');
is( $workflow->state, 'TEST_GREEDY_OR',
    'wfcond state after test_greedy_or' );
$workflow->execute_action('greedy_or_1');
is( $workflow->state, 'INITIALIZED',
    'wfcond state after greedy_or_1' );

$workflow->execute_action('test_greedy_or');
is( $workflow->state, 'TEST_GREEDY_OR',
    'wfcond state after test_greedy_or' );
$workflow->execute_action('greedy_or_2');
is( $workflow->state, 'SUBTEST_FAIL',
    'wfcond state after test_greedy_or' );

$workflow->execute_action('ack_subtest_fail');
is( $workflow->state, 'INITIALIZED',
    'wfcond state after ack_subtest_fail' );

##################################################
# DONE WITH ALL TESTS
##################################################

$workflow->execute_action('tests_done');
is( $workflow->state, 'SUCCESS', 'end workflow state SUCCESS' );

# Get our condition
#my $cond = $workflow->get_condition('greedy_or_1');
#is( $cond, 'greedy_or', 'get greedy_or_1 condition');

# Get the data needed for action 'upload file' (assumed to be
# available in the current state) and display the fieldname and
# description

#print "Action 'upload file' requires the following fields:\n";
#foreach my $field ( $workflow->get_action_fields( 'FOO' ) ) {
#    print $field->name, ": ", $field->description,
#          "(Required? ", $field->is_required, ")\n";
#}

# Add data to the workflow context for the validators, conditions and
# actions to work with

my $context      = $workflow->context;
my $user         = 'test user';
my @sections     = qw( section1 section2 section3 );
my $path_to_file = '/dev/null';
$context->param( current_user => $user );
$context->param( sections     => \@sections );
$context->param( path         => $path_to_file );

# Execute one of them
#$workflow->execute_action( 'upload file' );

# Later.... fetch an existing workflow
#my $id = get_workflow_id_from_user( ... );
#my $workflow = $factory->fetch_workflow( 'myworkflow', $id );
#print "Current state: ", $workflow->state, "\n";

#is( evaluate($test_eq),             1,  "cond test_eq" );
#is( evaluate($test_eq_fail),        '', "cond test_eq_fail" );
#is( evaluate($test_lazyor_2),       1,  "cond test_lazyor_2" );
#is( evaluate($test_greedyor_2),     2,  "cond test_greedyor_2" );
#is( evaluate($test_greedyor_2_ref), 2,  "cond test_greedyor_2_ref" );

