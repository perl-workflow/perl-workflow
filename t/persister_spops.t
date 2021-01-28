#!/usr/bin/env perl

use strict;
use lib qw(../lib lib ../t t);
use TestUtil;

use constant NUM_TESTS => 18;
use Test::More;

eval "require SPOPS";
if ( $@ ) {
    plan skip_all => 'SPOPS not installed';
}
my $ver = SPOPS->VERSION;
if ( $ver < 0.81 ) {
    plan skip_all => "You need SPOPS version 0.81+ to run tests (you have: $ver)";
}
plan tests => NUM_TESTS;

require TestUtil;
require Workflow::Factory;

require_ok( 'Workflow::Persister::SPOPS' );

my $WF_CLASS        = 'My::Persist::Workflow';
my $HIST_CLASS      = 'My::Persist::WorkflowHistory';
my $TICKET_CLASS    = 'My::Persist::Ticket';
my $WF_TICKET_CLASS = 'My::Persist::WorkflowTicket';

my $classes = spops_initialize() || [];
unless ( scalar @{ $classes } == 4 ) {
    die "Did not initialize classes properly; classes initialized: ",
        join( ', ', @{ $classes } ), "\n";
}

my @persisters = (
    { name           => 'TestPersister',
      class          => 'Workflow::Persister::SPOPS',
      workflow_class => $WF_CLASS,
      history_class  => $HIST_CLASS }
);

my $factory = Workflow::Factory->instance;
$factory->add_config( persister => \@persisters );
TestUtil->init_factory();

my ( $wf_id, $create_date );

{
    my $wf = $factory->create_workflow( 'Ticket' );
    $wf_id = $wf->id;
    ok( $wf_id, 'Created workflow has ID' );
    my $wf_persist = $WF_CLASS->fetch( $wf_id );
    is( $wf_persist->id, $wf_id,
        'Workflow and persisted data ID match' );
    is( $wf_persist->state, $wf->state,
        '...state matches' );
    is( $wf_persist->type, $wf->type,
        '...type matches' );
    is( ref( $wf_persist->last_update ), 'DateTime',
        '...date of correct type (DateTime)' );

    # Set the date to a few seconds ago so we can ensure the
    # comparison after execute_action() works okay below...

    $create_date = $wf_persist->last_update->epoch - 20;
    $wf_persist->last_update( DateTime->from_epoch( epoch => $create_date ) );
    $wf_persist->save;

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
    my $wf_persist = $WF_CLASS->fetch( $wf_id );
    is( $wf_persist->state, 'TIX_CREATED',
        'State of persisted workflow correct' );
    my $wf_ticket = $WF_TICKET_CLASS->fetch( $wf_id );
    is( ref( $wf_ticket ), $WF_TICKET_CLASS,
        'State of persisted workflow-to-ticket link correct' );
    my $ticket = $TICKET_CLASS->fetch( $wf_ticket->ticket_id );
    is( ref( $ticket ), $TICKET_CLASS,
        'State of persisted ticket ok' );
    isnt( $create_date, $wf_persist->last_update->epoch,
          'Update time of persisted workflow changed from creation time' );
    my @history = $wf->get_history();
    is( scalar @history, 2,
        'Number of history objects after executing action' );
}

sub spops_initialize {
    my $date_format = '%Y-%m-%d %H:%M:%S';
    my %config = (
        workflow => {
            class               => $WF_CLASS,
            isa                 => [ 'SPOPS::Key::Random', 'SPOPS::Loopback' ],
            rules_from          => [ 'SPOPS::Tool::DateConvert' ],
            field               => [
                qw( workflow_id type state last_update )
            ],
            id_field            => 'workflow_id',
            convert_date_class  => 'DateTime',
            convert_date_format => $date_format,
            convert_date_field  => [ 'last_update' ],
        },
        workflow_history => {
            class               => $HIST_CLASS,
            isa                 => [ 'SPOPS::Key::Random', 'SPOPS::Loopback' ],
            rules_from          => [ 'SPOPS::Tool::DateConvert' ],
            field               => [
                qw( workflow_hist_id workflow_id action description
                    state user history_date )
            ],
            id_field            => 'workflow_hist_id',
            convert_date_class  => 'DateTime',
            convert_date_format => $date_format,
            convert_date_field  => [ 'history_date' ],
        },
        ticket => {
            class               => $TICKET_CLASS,
            isa                 => [ 'SPOPS::Key::Random', 'SPOPS::Loopback' ],
            rules_from          => [ 'SPOPS::Tool::DateConvert' ],
            field               => [
                qw( ticket_id type subject description creator
                    status due_date last_update )
            ],
            id_field            => 'ticket_id',
            convert_date_class  => 'DateTime',
            convert_date_format => $date_format,
            convert_date_field  => [ 'due_date', 'last_update' ],
        },
        workflow_ticket => {
            class               => $WF_TICKET_CLASS,
            isa                 => [ 'SPOPS::Loopback' ],
            field               => [ qw( workflow_id ticket_id ) ],
            id_field            => 'ticket_id',
        },
    );
    require SPOPS::Initialize;
    return SPOPS::Initialize->process({ config => \%config });
}
