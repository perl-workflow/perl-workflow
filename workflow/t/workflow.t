# -*-perl-*-

# $Id$

use strict;
use Test::More  tests => 4;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init({ level => $WARN,
                           file  => ">> workflow_tests.log" });

require_ok( 'Workflow' );

require TestUtil;
require Workflow::Factory;

my $factory = Workflow::Factory->instance;
TestUtil->init_factory();
TestUtil->init_mock_persister();

eval { TestUtil->add_config( workflow => 'workflow_observer.xml' ) };
ok( ! $@, "Added configuration for workflow with observer" );

my $wf = $factory->create_workflow( 'ObservedTicket' );
my ( $o_created, @extra ) = SomeObserver->get_observations;
ok( defined $o_created && scalar @extra == 0,
    'One observation sent on workflow create' );
is( $o_created->[1], 'create',
    'Observation sent with the correct action' );
