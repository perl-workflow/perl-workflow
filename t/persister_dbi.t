#!/usr/bin/env perl

use strict;
use lib qw(../lib lib ../t t);

use Mock::MonkeyPatch;
use TestUtil;
use constant NUM_TESTS => 50;

use Test::More;
use Test::Exception;

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
}
plan tests => NUM_TESTS;

require Workflow::Factory;

my $TICKET_CLASS = 'TestApp::Ticket';
my $DATE_FORMAT = '%Y-%m-%d %H:%M';

require_ok( 'Workflow::Persister::DBI' );
require_ok( 'TestPersisterElsewhere' );

my @persisters = ({
    name  => 'TestPersister',
    class => 'Workflow::Persister::DBI',
    dsn   => 'DBI:Mock:',
    user  => 'DBTester',
    date_format => $DATE_FORMAT,
},
{
    name  => 'DBIFromElsewhere',
    class => 'TestPersisterElsewhere',
    driver=> 'Pg',
});
my $i = 0;
my $factory = Workflow::Factory->instance;
lives_ok { $factory->add_config( persister => \@persisters ) }
   'Successful persister creation' ;
TestUtil->init_factory();

my $persister = $factory->get_persister( 'DBIFromElsewhere' );
is ($persister->driver, 'Pg', 'DBI from elsewhere: driver is Pg');


my ( $wf_id, $create_date );

$persister = $factory->get_persister( 'TestPersister' );
my $handle = $persister->handle;

is ($persister->dsn(), 'DBI:Mock:', 'Got back dsn from config.');
is ($persister->date_format(), '%Y-%m-%d %H:%M', 'Got back date format from config.');

my ( $wf );

{
    $wf = $factory->create_workflow( 'Ticket' );
    $wf_id = $wf->id;
    ok( $wf_id, 'Created workflow has ID' );
    my $history = $handle->{mock_all_history};
    is( scalar @{ $history }, 2,
        'Correct number of statements created' );
    my $wf_history  = $history->[0];
    TestUtil->check_tracker(
        $wf_history, 'create workflow',
        qr/^INSERT INTO "workflow" \( "type", "state", "last_update", "workflow_id" \)/,
        [ 'type', 'state', 'current date',
          'random ID of correct length' ],
        [ 'Ticket', 'INITIAL', $wf_history->{bound_params}->[2],
          sub { my ( $val ) = @_; return ( length( $val ), 8 ) } ]
    );

    my $hst_history = $history->[1];
    TestUtil->check_workflow_history(
        $hst_history,
        [ $wf_id, 'Create workflow', 'Create new workflow',
          'INITIAL', 'n/a', $hst_history->{bound_params}->[5],
          sub { my ( $val ) = @_; return ( length( $val ), 8 ) } ]
    );
    $handle->{mock_clear_history} = 1;

    # Load history back from the database
    $handle->{mock_add_resultset} = [
        [ qw/ workflow_hist_id workflow_id action description state
          workflow_user history_date / ],
        [ $history->[1]->{bound_params}->[6],
          $wf_id, "Create workflow", "Create new workflow", 'INITIAL',
          "n/a", $history->[1]->{bound_params}->[5], ]
        ];
    my @hist = $wf->get_history;
    $handle->{mock_clear_history} = 1;
}

{
    my $now    = DateTime->now();
    my $nowstr = $now->strftime( $DATE_FORMAT );
    # Prevent test failure due to minute-wrapping between
    # preparing the query and verifying the result
    my $mock = Mock::MonkeyPatch->patch(
        'DateTime::now' => sub { $now->clone }
        );

    TestUtil->set_new_ticket_context( $wf );
    my $old_state = $wf->state();
    $wf->execute_action( 'TIX_NEW' );
    is( $wf->state(), 'TIX_CREATED',
        'State of modified workflow correct' );
    my $ticket = $wf->context->param( 'ticket' );
    is( ref( $ticket ), 'TestApp::Ticket',
        'Ticket added to context by action' );
    my $ticket_id = $ticket->id;

    my $history = $handle->{mock_all_history};
    is( scalar( @{ $history } ), 4,
                'Correct number of statements to update workflow, create history and create ticket' );

    my $tix_create = $history->[0];
    my %ticket_info = TestUtil->get_new_ticket_info();
    TestUtil->check_tracker(
        $tix_create, 'create ticket',
        qr/^INSERT INTO "ticket" \( "ticket_id", "type", "subject", "description", "creator", "status", "due_date", "last_update" \)/,
        [ 'ticket ID', 'type', 'subject',
          'description', 'creator', 'status',
          'due date', 'last update' ],
        [ $ticket_id, $ticket_info{type}, $ticket_info{subject},
          $ticket_info{description}, $ticket_info{creator}, $old_state,
          $ticket_info{due_date}->strftime( '%Y-%m-%d' ), $nowstr ]
    );

    my $link_create = $history->[1];
    my $wf_update = $history->[2];
    my $hst_update = $history->[3];
    my $history_desc = "New ticket created of type '$ticket_info{type}' " .
                       "and subject '$ticket_info{subject}'";
    TestUtil->check_workflow_history(
        $hst_update,
        [ $wf_id, 'Create ticket', $history_desc,
          'TIX_CREATED', $ticket_info{creator}, $nowstr,
          sub { my ( $val ) = @_; return ( length( $val ), 8 ) } ]
    );


#    my $wf_ticket = fetch_workflow_ticket_link( $persister, $wf_id );
#    is( $wf_ticket->{workflow_id}, $wf_id,
#        'Workflow ID of persisted workflow-to-ticket link correct' );
#    ok( $wf_ticket->{ticket_id},
#        'Persisted workflow-to-ticket link has ticket ID' );
#    my $ticket = $TICKET_CLASS->fetch( $wf_ticket->{ticket_id} );
#    is( ref( $ticket ), $TICKET_CLASS,
#        'State of persisted ticket ok' );
#    isnt( $create_date, $wf_persist->{last_update}->epoch,
#          'Update time of persisted workflow changed from creation time' );
#    my @history = $wf->get_history();
#    is( scalar @history, 2,
#        'Number of history objects after executing action' );
}


{
    # Seed the resultset with an empty row...

    $handle->{mock_add_resultset} = [];
    my $wf = $factory->fetch_workflow( 'Ticket', 42 );
    is( $wf, undef,
        'Trying to fetch non-existent workflow returns undef' );

}


{
    $handle->{mock_clear_history} = 1;
    my $wf = $factory->create_workflow( 'Ticket' );
    my $wf_hist = $handle->{mock_all_history};
    $handle->{mock_clear_history} = 1;
    $handle->{mock_add_resultset} =
        [
         [ qw/workflow_hist_id workflow_id
           action description state workflow_user
              history_date / ],
         [ 'def', $wf->id, 'Create workflow', 'Create new workflow',
          'INITIAL', 'n/a', $wf_hist->[1]->{bound_params}->[5] ]
        ];
    my @history = $wf->get_history();


    my $stmt = $handle->{mock_all_history}->[0]->statement;
    like($stmt,
         qr/SELECT "workflow_hist_id", "workflow_id", "action", "description", "state", "workflow_user", "history_date"/,
         'Quote workflow history table identifiers');
    like($stmt, qr/FROM "workflow_history"/, 'Query from "workflow_history" table');
    like($stmt, qr/WHERE "workflow_id" = ?/, 'Query history by "workflow_id"');
    like($stmt, qr/ORDER BY "history_date" DESC/, 'Ordering on "history_date"');
}
