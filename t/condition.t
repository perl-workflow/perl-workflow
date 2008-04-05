# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 11;
use Test::Exception;

require_ok( 'Workflow::Condition' );

dies_ok { Workflow::Condition->evaluate() };

require_ok( 'Workflow::State' );

my $factory = TestUtil->init_factory();
TestUtil->init_mock_persister();

# Call Type2 first. It gets loaded second, so this
# should verify that both types are available.
my $wf2 = $factory->create_workflow( 'Type2' );

my $wf_state = $wf2->_get_workflow_state();
is( $wf_state->state(), 'INITIAL', 'In INITIAL state.');

TestUtil->set_new_ticket_context( $wf2 );
ok( $wf2->execute_action('TIX_NEW'), 'Ran TIX_NEW action.');

$wf_state = $wf2->_get_workflow_state();

my @conditions = $wf_state->get_conditions( 'Ticket_Close' );

# The Type2 version of the HasUser condition should be a
# TestApp::Condition::HasUserType.

is( $conditions[0]->name(), 'HasUser', 'Got a HasUser condition.');
isa_ok( $conditions[0], 'TestApp::Condition::HasUserType');

# Call Ticket type.
my $wf1 = $factory->create_workflow( 'Ticket' );

$wf_state = $wf1->_get_workflow_state();
is( $wf_state->state(), 'INITIAL', 'In INITIAL state.');

TestUtil->set_new_ticket_context( $wf1 );
ok( $wf1->execute_action('TIX_NEW'), 'Ran TIX_NEW action.');

$wf_state = $wf1->_get_workflow_state();

@conditions = $wf_state->get_conditions( 'TIX_EDIT' );

# The Ticket version of the HasUser condition should be a
# TestApp::Condition::HasUser.

is( $conditions[0]->name(), 'HasUser', 'Got a HasUser condition.');
isa_ok( $conditions[0], 'TestApp::Condition::HasUser');
