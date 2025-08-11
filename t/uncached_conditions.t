use strict;
use warnings;
no warnings 'once';

use lib 't/lib';
use Test::More;
use TestUtil;
use Workflow::Condition;
use Workflow::Factory;
use Data::Dumper;

plan tests => 3;

$Workflow::Condition::CACHE_RESULTS = 0;



my $factory = Workflow::Factory->instance();
$factory->add_config_from_file(
    workflow  => "t/workflow_cached_condition.d/workflow_cached_condition.xml",
    action    => "t/workflow_cached_condition.d/workflow_cached_condition_action.xml",
    condition => "t/workflow_cached_condition.d/workflow_cached_condition_condition.xml",
);
TestUtil->init_mock_persister();
my $wf = $factory->create_workflow( 'CachedCondition' );
my $does_change;

my @actions = $wf->get_current_actions();
# due to hash randomization, it can be the case that either !EvenCounts
# is executed befor EvenCounts or the other way around. This results in
# either 1 or 3 items being returned on Perl versions with randomization
ok(scalar @actions, 'Actions available');
my $old_actions = join q{, }, sort @actions;

CHECK_TIME_CHANGE:
for (my $i = 0; $i < 5; $i++) {
    my $curr_actions = join q{, }, sort ( $wf->get_current_actions() );
    if ($old_actions ne $curr_actions) {
        # the current action is not the one from before, this is good
        # as we need to recheck the conditions everytime someone wants
        # a list of all actions
        $does_change = 1;
        last CHECK_TIME_CHANGE;
    }
    $old_actions = $curr_actions;

    # Change the external state the conditions depend on
    $TestCachedApp::Condition::EvenCounts::count++;
}
ok($does_change, 'Available actions change with external state');

$does_change = 0;
CHECK_STATE_CHANGE:
for (my $i = 0; $i < 5; $i++) {
    # execute a null action to go to the second state
    $wf->execute_action('FORWARD');
    # and go back again
    $wf->execute_action('BACK');

    my $curr_actions = join q{, }, sort ( $wf->get_current_actions() );
    #diag $curr_actions;
    if ($old_actions ne $curr_actions) {
        # the current action is not the one from before, this is good
        # as we need to recheck the conditions everytime someone wants
        # a list of all actions
        $does_change = 1;
        last CHECK_STATE_CHANGE;
    }
    $old_actions = $curr_actions;
}
ok($does_change, 'Available actions change when changing states');

