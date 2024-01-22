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
    plan tests => 33;
}

require_ok( 'Workflow' );

my $factory = TestUtil->init_factory();
TestUtil->init_mock_persister();

my $persister = $factory->get_persister( 'TestPersister' );
my $handle = $persister->handle;

# add a separate configuration for the observed workflow

eval {
    $factory->add_config_from_file( workflow => 't/workflow.xml',
                                    observer => 't/workflow_independent_observers.xml' )
};
$@ && diag( "Error: $@" );
ok( ! $@, "Added configuration for workflow with observer" );

{
    SomeObserver->clear_observations;
    my $wf = $factory->create_workflow( 'Ticket' );
    ok( $wf->isa( 'Workflow' ),
        'Instantiated workflow is of expected type Workflow' );
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

  my $wf = $factory->fetch_workflow( 'Ticket', 1 );
  is( $wf->type(), 'Ticket', 'Got workflow type.');
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

    my $wf = $factory->fetch_workflow( 'Ticket', 1 );
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
    my $wf = $factory->fetch_workflow( 'Ticket', 1 );
    SomeObserver->clear_observations;
    $wf->context->param({
        subject => 'subject',
        description => 'description',
        creator => 'creator',
        type => 'type'
                        }
        );
    $wf->execute_action( 'TIX_NEW' );
    my @observations = SomeObserver->get_observations;
    is( scalar @observations, 14,
        'Seven observations sent on workflow execute to two observers' );

    is( $observations[4]->[2], 'add history',
        'History observation generated first to first observer' );
    is( $observations[5]->[2], 'add history',
        'History observation generated first to second observer' );

    is( $observations[6]->[2], 'save',
        'Save observation generated first to first observer' );
    is( $observations[7]->[2], 'save',
        'Save observation generated first to second observer' );

    is( $observations[8]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[8]->[2], 'completed',
        'Class observer sent the correct execute action' );
    is( $observations[8]->[3]->{state}, 'INITIAL',
        'Class observer sent the correct old state for execute' );

    is( $observations[9]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[9]->[2], 'completed',
        'Subroutine observer sent the correct execute action' );
    is( $observations[9]->[3]->{state}, 'INITIAL',
        'Subroutine observer sent the correct old state for execute' );

    is( $observations[10]->[0], 'class',
        'Observation sent to configured class observer first' );
    is( $observations[10]->[2], 'state change',
        'Class observer sent the correct state change action' );
    is( $observations[10]->[3]->{from}, 'INITIAL',
        'Class observer sent the correct old state for state change' );

    is( $observations[11]->[0], 'sub',
        'Observation sent to configured subroutine observer second' );
    is( $observations[11]->[2], 'state change',
        'Subroutine observer sent the correct state change action' );
    is( $observations[11]->[3]->{from}, 'INITIAL',
        'Subroutine observer sent the correct old state for state change' );
}
