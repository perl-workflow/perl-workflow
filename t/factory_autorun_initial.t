
use strict;
use warnings;
use lib qw(t);
use Test::More;
use Test::Exception;
use TestUtil;
use Workflow::Factory;

plan tests => 1;

my $factory = Workflow::Factory->instance();
$factory->add_config_from_file(
    workflow  => "t/workflow_autorun_initial.d/workflow.xml",
    action    => "t/workflow_autorun_initial.d/workflow_action.xml"
);
TestUtil->init_mock_persister();
my $wf = $factory->create_workflow( 'AutorunInitial' );

is( $wf->state, 'FINAL', 'The INITIAL state was correctly executed by teh factory' );

