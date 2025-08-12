
use strict;
use warnings;
use lib qw(t t/lib);
use Test::More;
use Test::Exception;
use TestUtil;
use Workflow::Factory;

plan tests => 2;

my $factory = Workflow::Factory->instance();
$factory->add_config_from_file(
    workflow  => "t/workflow_autorun_initial.d/workflow.xml",
    action    => "t/workflow_autorun_initial.d/workflow_action.xml",
    observer  => "t/workflow_autorun_initial.d/workflow_observer.xml"
);

# prevent 'used only once' warning:
@AutorunInitialObserver::events = ();
TestUtil->init_mock_persister();
my $wf = $factory->create_workflow( 'AutorunInitial' );

is( $wf->state, 'FINAL', 'The INITIAL state was correctly executed by teh factory' );

is_deeply( \@AutorunInitialObserver::events,
           [
            ['create'],
            ['startup'],
            ['run'],
            ['save'],
            ['completed', {'action' => 'RUN', 'state' => 'INITIAL', 'autorun' => !!1}],
            ['state change', {'from' => 'INITIAL', 'to' => 'FINAL', 'action' => 'RUN'}],
            ['finalize']
           ],
           '');
