# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 21;

require_ok( 'Workflow::State' );

my $factory;

$factory = TestUtil->init_factory();
TestUtil->init_mock_persister();

# Run the tests with XML-based config.
TestUtil::run_state_tests($factory);


#### 11/18/2008 - Bob Stockdale ####
# Test the naming of the 'test' conditions -- all were formerly named
# 'evaluate'
my $wf         = $factory->create_workflow('TestCondition');
my $state      = $wf->_get_workflow_state('Ticket_Created');
my @conditions = $state->get_conditions('Ticket_Close');

is( $conditions[0]->name(), '_Ticket_Created_Ticket_Close_condition_1',
    q{Got expected name for 'test' condition} );

is( $conditions[1]->name(), '_Ticket_Created_Ticket_Close_condition_2',
    q{Got expected name for second 'test' condition} );
