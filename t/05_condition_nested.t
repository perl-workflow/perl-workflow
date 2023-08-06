#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(t);

use Test::More;
use Log::Any qw( $log );

my $debug = $ENV{TEST_DEBUG};

# base name used to find config files
my $cfgbase = $0;
$cfgbase =~ s/\.t$/.d/;



require Workflow::Factory;
require Workflow::Persister::DBI;


plan tests => 13;

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
# RUN TESTS FOR 'Workflow::Condition::LazyOR'
##################################################

$workflow->execute_action('test_lazy_or');
is( $workflow->state, 'TEST_LAZY_OR', 'wfcond state after test_lazy_or' );
$workflow->execute_action('lazy_or_1');
is( $workflow->state, 'SUBTEST_FAIL', 'wfcond state after lazy_or_1' );
$workflow->execute_action('ack_subtest_fail');
is( $workflow->state, 'INITIALIZED', 'wfcond state after ack_subtest_fail' );

$workflow->execute_action('test_lazy_or');
is( $workflow->state, 'TEST_LAZY_OR', 'wfcond state after test_lazy_or' );
$workflow->execute_action('lazy_or_2');
is( $workflow->state, 'INITIALIZED', 'wfcond state after lazy_or_2' )
    or $workflow->execute_action('ack_subtest_fail');

##################################################
# DONE WITH ALL TESTS
##################################################

$workflow->execute_action('tests_done');
is( $workflow->state, 'SUCCESS', 'end workflow state SUCCESS' );

