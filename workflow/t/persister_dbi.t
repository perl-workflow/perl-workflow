# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use constant NUM_TESTS => 43;
use Test::More;

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
}
plan tests => NUM_TESTS;

require Workflow::Factory;

my $TICKET_CLASS = 'TestApp::Ticket';
my $DATE_FORMAT = '%Y-%m-%d %H:%M';

require_ok( 'Workflow::Persister::DBI' );

my @persisters = ({
    name  => 'TestPersister',
    class => 'Workflow::Persister::DBI',
    dsn   => 'DBI:Mock:',
    user => 'DBTester',
    date_format => $DATE_FORMAT,
});

my $factory = Workflow::Factory->instance;
$factory->add_config( persister => \@persisters );
TestUtil->init_factory();

my ( $wf_id, $create_date );

my $persister = $factory->get_persister( 'TestPersister' );
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
        qr/^INSERT INTO workflow \( type, state, last_update, workflow_id \)/,
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
}

{
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
        qr/^INSERT INTO ticket \( ticket_id, type, subject, description, creator, status, due_date, last_update \)/,
        [ 'ticket ID', 'type', 'subject',
          'description', 'creator', 'status',
          'due date', 'last update' ],
        [ $ticket_id, $ticket_info{type}, $ticket_info{subject},
          $ticket_info{description}, $ticket_info{creator}, $old_state,
          $ticket_info{due_date}->strftime( '%Y-%m-%d' ), DateTime->now->strftime( $DATE_FORMAT ) ]
    );

    my $link_create = $history->[1];
    my $wf_update = $history->[2];
    my $hst_update = $history->[3];
    my $history_desc = "New ticket created of type '$ticket_info{type}' " .
                       "and subject '$ticket_info{subject}'";
    TestUtil->check_workflow_history(
        $hst_update,
        [ $wf_id, 'Create ticket', $history_desc,
          'TIX_CREATED', $ticket_info{creator}, DateTime->now->strftime( $DATE_FORMAT ),
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
