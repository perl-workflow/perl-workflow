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
my $CONF_FILE = $cfgbase . '/log4perl.conf';

require Log::Log4perl;
if ($debug) {
    if ( -f $LOG_FILE ) {
        unlink($LOG_FILE);
    }
    Log::Log4perl::init($CONF_FILE);
}

plan tests => 21;

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
# RUN TESTS FOR 'Workflow::Condition::GreedyOR'
##################################################

#diag( "Available actions: " . join(', ', $workflow->get_current_actions));
$workflow->execute_action('test_greedy_or');
is( $workflow->state, 'TEST_GREEDY_OR', 'wfcond state after test_greedy_or' );
$workflow->execute_action('greedy_or_1');
is( $workflow->state, 'INITIALIZED', 'wfcond state after greedy_or_1' )
    or $workflow->execute_action('ack_subtest_fail');

$workflow->execute_action('test_greedy_or');
is( $workflow->state, 'TEST_GREEDY_OR', 'wfcond state after test_greedy_or' );
$workflow->execute_action('greedy_or_2');
is( $workflow->state, 'SUBTEST_FAIL', 'wfcond state after test_greedy_or' );
$workflow->execute_action('ack_subtest_fail');
is( $workflow->state, 'INITIALIZED', 'wfcond state after ack_subtest_fail' );

##################################################
# RUN TESTS FOR 'Workflow::Condition::LazyAND'
##################################################

$workflow->execute_action('test_lazy_and');
is( $workflow->state, 'TEST_LAZY_AND', 'wfcond state after test_lazy_and' );
$workflow->execute_action('lazy_and_1');
is( $workflow->state, 'SUBTEST_FAIL', 'wfcond state after lazy_and_1' );
$workflow->execute_action('ack_subtest_fail');
is( $workflow->state, 'INITIALIZED', 'wfcond state after ack_subtest_fail' );

$workflow->execute_action('test_lazy_and');
is( $workflow->state, 'TEST_LAZY_AND', 'wfcond state after test_lazy_and' );
$workflow->execute_action('lazy_and_2');
is( $workflow->state, 'INITIALIZED', 'wfcond state after lazy_and_2' )
    or $workflow->execute_action('ack_subtest_fail');

##################################################
# RUN TESTS FOR 'Workflow::Condition::CheckReturn'
##################################################

$workflow->execute_action('test_check_return');
is( $workflow->state, 'TEST_CHECK_RETURN',
    'wfcond state after test_check_return' );
$workflow->execute_action('check_return_1');
is( $workflow->state, 'INITIALIZED', 'wfcond state after check_return_1' )
    or $workflow->execute_action('ack_subtest_fail');

$workflow->execute_action('test_check_return');
is( $workflow->state, 'TEST_CHECK_RETURN',
    'wfcond state after test_check_return' );
$workflow->execute_action('check_return_2');
is( $workflow->state, 'SUBTEST_FAIL', 'wfcond state after check_return_2' );
$workflow->execute_action('ack_subtest_fail');
is( $workflow->state, 'INITIALIZED', 'wfcond state after ack_subtest_fail' );

$workflow->execute_action('test_check_return');
is( $workflow->state, 'TEST_CHECK_RETURN',
    'wfcond state after test_check_return' );
$workflow->execute_action('check_return_3');
is( $workflow->state, 'SUBTEST_FAIL', 'wfcond state after check_return_3' );
$workflow->execute_action('ack_subtest_fail');
is( $workflow->state, 'INITIALIZED', 'wfcond state after ack_subtest_fail' );

##################################################
# DONE WITH ALL TESTS
##################################################

$workflow->execute_action('tests_done');
is( $workflow->state, 'SUCCESS', 'end workflow state SUCCESS' );

