# -*-perl-*-


use strict;
use lib 't';
use TestUtil;
use constant NUM_TESTS => 15;
use Test::More;
use Log::Log4perl     qw( get_logger );
use TestDBUtil;

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
}

eval "require DBD::SQLite";
if ( $@ ) {
    plan skip_all => 'DBD::SQLite not installed';
}

TestDBUtil::create_tables({
			   db_type => 'sqlite',
			   db_file => 'workflow.db',
			  });

plan tests => NUM_TESTS;

require Workflow::Factory;

my $TICKET_CLASS = 'TestApp::Ticket';
my $DATE_FORMAT = '%Y-%m-%d %H:%M';

require_ok( 'Workflow::Persister::DBI' );

my @persisters = ({
    name  => 'TestPersister',
    class => 'Workflow::Persister::DBI',
    dsn   => 'dbi:SQLite:dbname=db/workflow.db',
    user => 'DBTester',
    date_format => $DATE_FORMAT,
    autocommit => 0,
});

my $factory = Workflow::Factory->instance;
$factory->add_config( persister => \@persisters );
TestUtil->init_factory();

my ( $wf_id, $create_date );

my $persister = $factory->get_persister( 'TestPersister' );
my $handle = $persister->handle;

is ($persister->dsn(), 'dbi:SQLite:dbname=db/workflow.db', 'Got back dsn from config.');
is ($persister->date_format(), '%Y-%m-%d %H:%M', 'Got back date format from config.');
is ($persister->autocommit(), '0', 'Autocommit turned off by config.');

# Create a handle to verify commits to the db.
my $test_dbh =
  DBI->connect( $persister->dsn, $persister->user, $persister->password )
  || die "Cannot connect to database: $DBI::errstr";

my ( $wf );

{
    $wf = $factory->create_workflow( 'Ticket' );
    $wf_id = $wf->id;
    ok( $wf_id, "Created workflow has ID $wf_id." );

    # Verify wf records.
    my $wf_ref = get_wf_records($persister, $test_dbh, $wf_id);

    is( (scalar keys %$wf_ref), 1, 'Commited one workflow record.');
    is( $wf_ref->{$wf_id}{state}, 'INITIAL', 'WF in INITIAL state.');

    # Verify history records.
    my $history_ref = get_history_records($persister, $test_dbh, $wf_id);

    is( (scalar keys %$history_ref), 1, 'Commited one history record.');
    my ($hist_id) = keys %$history_ref;
    is( $history_ref->{$hist_id}{state}, 'INITIAL',
	'History entry with WF in INITIAL state.');
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

    my $wf_ref = get_wf_records($persister, $test_dbh, $wf_id);

    is( $wf_ref->{$wf_id}{state}, 'TIX_CREATED', 'WF in CREATED state.');

    my $history_ref = get_history_records($persister, $test_dbh, $wf_id);

    is( (scalar keys %$history_ref), 2, 'Two history records found.');
    my @hist_ids = sort {$a cmp $b} keys %$history_ref;

    is( $history_ref->{$hist_ids[-1]}{state}, 'TIX_CREATED',
	'History entry with WF in TIX_CREATED state.');

# Copied these over still commented from the original persister_dbi test.
# Not sure if it's valuable to get them working in this test.

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

    my $wf = $factory->fetch_workflow( 'Ticket', 42 );
    is( $wf, undef,
        'Trying to fetch non-existent workflow returns undef' );

}

sub get_wf_records{
  my $persister = shift;
  my $test_dbh = shift;
  my $wf_id = shift;

  my $statement = 'select * from '
    . $persister->workflow_table . " where workflow_id = $wf_id";
  my $wf_ref = $test_dbh->selectall_hashref($statement, 'workflow_id');

  return $wf_ref;
}

sub get_extra_data_records{
  my $persister = shift;
  my $test_dbh = shift;
  my $wf_id = shift;

  my $statement = 'select * from '
    . $persister->workflow_table . " where workflow_id = $wf_id";
  my $wf_ref = $test_dbh->selectall_hashref($statement, 'workflow_id');

  return $wf_ref;
}

sub get_history_records{
  my $persister = shift;
  my $test_dbh = shift;
  my $wf_id = shift;

  my $statement = 'select * from '
    . $persister->history_table . " where workflow_id = $wf_id";
  my $history_ref = $test_dbh->selectall_hashref($statement, 'workflow_hist_id');

  return $history_ref;
}
