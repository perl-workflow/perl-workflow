# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use File::Path            qw( rmtree );
use File::Spec::Functions qw( catdir curdir rel2abs );
use Test::More  tests => 19;

require Workflow::Factory;

my $persist_dir = catdir( rel2abs( curdir() ), 'tmp_file' );
unless ( -d $persist_dir ) {
    mkdir( $persist_dir, 0777 );
}

my $TICKET_CLASS = 'TestApp::Ticket';

require_ok( 'Workflow::Persister::File' );

my @persisters = (
    { name           => 'TestPersister',
      class          => 'Workflow::Persister::File',
      path           => $persist_dir, }
);

my $factory = Workflow::Factory->instance;
$factory->add_config( persister => \@persisters );
TestUtil->init_factory();

my ( $wf_id, $create_date );

my $persister = $factory->get_persister( 'TestPersister' );

{
    my $wf = $factory->create_workflow( 'Ticket' );
    $wf_id = $wf->id;
    ok( $wf_id, 'Created workflow has ID' );
    my $wf_persist = $persister->fetch_workflow( $wf_id );
    is( $wf_persist->{id}, $wf_id,
        'Workflow and persisted data ID match' );
    is( $wf_persist->{state}, $wf->state,
        '...state matches' );
    is( $wf_persist->{type}, $wf->type,
        '...type matches' );
    is( ref( $wf_persist->{last_update} ), 'DateTime',
        '...date of correct type (DateTime)' );

    # Set the date to a few seconds ago so we can ensure the
    # comparison after execute_action() works okay below...

    $create_date = $wf_persist->{last_update}->epoch - 20;

    my @history = $wf->get_history();
    is( scalar @history, 1,
        'Number of history objects after create' );
    my $wf_history = $history[0];
    ok( $wf_history->id,
        'History object has ID' );
    is( $wf_history->workflow_id, $wf_id,
        'Workflow ID matches that in history' );
    is( $wf_history->action, 'Create workflow',
        'Action matches value set in Factory' );
    is( $wf_history->description, 'Create new workflow',
        'Description matches value set in Factory' );
    is( $wf_history->user, 'n/a',
        'User matches value set in Factory' );
}

{
    my $wf = $factory->fetch_workflow( 'Ticket', $wf_id );
    TestUtil->set_new_ticket_context( $wf );
    $wf->execute_action( 'TIX_NEW' );
    is( $wf->state, 'TIX_CREATED',
        'State of modified workflow correct' );
    my $wf_persist = $persister->fetch_workflow( $wf_id );
    is( $wf_persist->{state}, 'TIX_CREATED',
        'State of persisted workflow correct' );
    my $wf_ticket = fetch_workflow_ticket_link( $persister, $wf_id );
    is( $wf_ticket->{workflow_id}, $wf_id,
        'Workflow ID of persisted workflow-to-ticket link correct' );
    ok( $wf_ticket->{ticket_id},
        'Persisted workflow-to-ticket link has ticket ID' );
    my $ticket = $TICKET_CLASS->fetch( $wf_ticket->{ticket_id} );
    is( ref( $ticket ), $TICKET_CLASS,
        'State of persisted ticket ok' );
    isnt( $create_date, $wf_persist->{last_update}->epoch,
          'Update time of persisted workflow changed from creation time' );
    my @history = $wf->get_history();
    is( scalar @history, 2,
        'Number of history objects after executing action' );
}

sub fetch_workflow_ticket_link {
    my ( $persister, $wf_id ) = @_;
    my $link_path = catdir( $persister->path,
                            "${wf_id}_workflow_ticket_link" );
    return $persister->constitute_object( $link_path );
}

END {
    if ( -d $persist_dir ) {
        rmtree( $persist_dir );
    }
}
