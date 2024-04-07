#!/usr/bin/env perl

use strict;
use lib qw(t);
use TestUtil;
use Test::More;
use Test::Exception;
use TestApp::CustomWorkflowHistory;

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
} else {
    plan tests => 42;
}

require_ok( 'Workflow' );

my $factory = TestUtil->init_factory();
TestUtil->init_mock_persister();

my $persister = $factory->get_persister( 'TestPersister' );
my $handle = $persister->handle;

# add a separate configuration for the observed workflow

eval {
    $factory->add_config_from_file( workflow => 't/workflow_observer.xml' )
};
$@ && diag( "Error: $@" );
ok( ! $@, "Added configuration for workflow with observer" );

{
    SomeObserver->clear_observations;
    my $wf = $factory->create_workflow( 'ObservedTicket' );
    ok( $wf->isa( 'TestApp::CustomWorkflow' ),
        'Instantiated workflow is of expected type TestApp::CustomWorkflow' );
    my @observations = SomeObserver->get_observations;
    is( scalar @observations, 2,
        'One observation sent on workflow create to two observers' );

    is( $observations[0]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[0]->[2], 'create',
        'Class observer sent the correct create action' );

    is( $observations[1]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[1]->[2], 'create',
        'Subroutine observer sent the correct create action' );
}

my $date = DateTime->now;
my @result_fields = ( 'state',   'last_update' );
my @result_data   = ( 'INITIAL', $date );

# Check object data.
{
  $handle->{mock_add_resultset} = [ \@result_fields, \@result_data ];

  my $wf = $factory->fetch_workflow( 'ObservedTicket', 1 );
  is( $wf->type(), 'ObservedTicket', 'Got workflow type.');
  is( $wf->description(),
      'This is the workflow for sample application Ticket',
      'Got workflow description.');
  is( $wf->time_zone(), 'floating', 'Got floating time zone.');
}

{
    SomeObserver->clear_observations;

    #The order of these statements are important, see RT #53909
    #https://rt.cpan.org/Ticket/Display.html?id=53909
    #So this is a temp work around since, the actual perl issue highlighted here
    #seem to be fixed in blead (See: Changes file)
    $handle->{mock_add_resultset} = [ \@result_fields, \@result_data ];

    my $wf = $factory->fetch_workflow( 'ObservedTicket', 1 );
    my @observations = SomeObserver->get_observations;

    is( scalar @observations, 2,
        'One observation sent on workflow fetch to two observers' );

    is( $observations[0]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[0]->[2], 'fetch',
        'Class observer sent the correct fetch action' );

    is( $observations[1]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[1]->[2], 'fetch',
        'Subroutine observer sent the correct fetch action' );
}

{
    $handle->{mock_add_resultset} = [ \@result_fields, \@result_data ];
    my $wf = $factory->fetch_workflow( 'ObservedTicket', 1 );
    SomeObserver->clear_observations;
    $wf->execute_action( 'null' );
    my @observations = SomeObserver->get_observations;

use Data::Dumper;
#warn Dumper     $observations[0];

    is( scalar @observations, 12,
        'Six observations sent on workflow execute to two observers' );

    is( $observations[0]->[2], 'startup',
        'Startup observation generated first to first observer' );
    is( $observations[1]->[2], 'startup',
        'Startup observation generated first to second observer' );

    is( $observations[2]->[2], 'run',
        'Run observation generated to first observer' );

    is( $observations[4]->[2], 'save',
        'Save observation generated to first observer' );

    is( $observations[6]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[6]->[2], 'completed',
        'Class observer sent the correct execute action' );
    is( $observations[6]->[3]->{state}, 'INITIAL',
        'Class observer sent the correct old state for execute' );

    is( $observations[7]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[7]->[2], 'completed',
        'Subroutine observer sent the correct execute action' );
    is( $observations[7]->[3]->{state}, 'INITIAL',
        'Subroutine observer sent the correct old state for execute' );

    is( $observations[8]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[8]->[2], 'state change',
        'Class observer sent the correct state change action' );
    is( $observations[8]->[3]->{from}, 'INITIAL',
        'Class observer sent the correct old state for state change' );

    is( $observations[9]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[9]->[2], 'state change',
        'Subroutine observer sent the correct state change action' );
    is( $observations[9]->[3]->{from}, 'INITIAL',
        'Subroutine observer sent the correct old state for state change' );

    is( $observations[10]->[2], 'finalize',
        'Finalize observation generated to first observer' );
}

{
    throws_ok {
        $factory->add_config(
            workflow => {
                type    => 'MyType',
                observer    => [
                    {
                        'sub'   => 'SomeObserver::i_dont_exist'
                    },
                ],
            },
        )
    } 'Workflow::Exception', "subroutine i_dont_exist causes exception";
    like($@, qr/not found/, "expected error string: $@");
}


{
    my $wf = $factory->create_workflow( 'ObservedTicket' );
    my @history = $wf->get_history;
    my $history = shift @history;

    # Test overridden defauts:

    # default: Create workflow
    is( $history->user, 'me', "Customized user set" );

    # default: n/a
    is( $history->description, 'New workflow', "Customized description set" );

    # default: Create new workflow
    is( $history->action, 'Create', "Customized action set" );
}


{
    $factory->add_config_from_file( workflow => 't/workflow.xml' );
    my $wf = $factory->create_workflow( 'Ticket' );
    my @history = $wf->get_history();
    for my $history (@history) {
        is( ref $history, 'TestApp::CustomWorkflowHistory',
            'History item is a TestApp::CustomWorkflowHistory' );
    }
    throws_ok {
        $wf->add_history(
            Workflow::History->new(
                {
                    action      => 'action',
                    description => 'description',
                    user        => 'me',
                })
            );
    } 'Workflow::Exception', "Adding the wrong history type fails";
    like($@, qr{I don't know how to add a history of type 'Workflow::History'},
         "expected error string, found: $@");
}
