use strict;
use warnings;

use lib 't';
use Test::More;
use Test::Exception;
use TestUtil;
use Workflow::Factory;
use Data::Dumper;
plan tests => 12;

my $factory = Workflow::Factory->instance();
$factory->add_config_from_file(
    workflow  => "workflow_cached_condition.xml",
    action    => "workflow_cached_condition_action.xml",
    condition => "workflow_cached_condition_condition.xml",
);
TestUtil->init_mock_persister();
my $wf = $factory->create_workflow( 'CachedCondition' );
my $does_change;

my @actions = $wf->get_current_actions();
is(scalar @actions, 2, 'Exactly two actions available');
my $old_actions = join q{, }, sort @actions;

CHECK_TIME_CHANGE:
for (my $i = 0; $i < 5; $i++) {
    my $curr_actions = join q{, }, sort ( $wf->get_current_actions() );
    # diag $curr_actions;
    if ($old_actions ne $curr_actions) {
        # the current action is not the one from before, this is good
        # as we need to recheck the conditions everytime someone wants
        # a list of all actions
        $does_change = 1;
        last CHECK_TIME_CHANGE;
    }
    $old_actions = $curr_actions;
}

ok($does_change, 'Available actions change over time');

$does_change = 0;
CHECK_STATE_CHANGE:
for (my $i = 0; $i < 5; $i++) {
    # execute a null action to go to the second state
    $wf->execute_action('FORWARD');
    # and go back again
    $wf->execute_action('BACK');

    my $curr_actions = join q{, }, sort ( $wf->get_current_actions() );
    # diag $curr_actions;
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

is( $wf->state, 'INITIAL', 'workflow is in INITIAL state' );
my $actions = join( ', ', sort $wf->get_current_actions() );
ok( ( $actions =~ m/FORWARD,/ ) ,
    'FORWARD action is available in workflow' );
$wf->context->param( alternative => 'yes' );
$actions = join( ', ', sort $wf->get_current_actions() );
ok( ( $actions =~ m/FORWARD-ALT,/ ) ,
    'Changed context makes FORWARD-ALT action available in workflow' );
# reset the workflow back to allowing FORWARD instead of FORWARD-ALT
$wf->context->param( alternative => '' );


# With one workflow in-flight, results of the other should
# not be influenced. So we create a second workflow which
# does *not* have FORWARD in its list of current actions and
# then we ask the original workflow (which *does* have it)
# for the fields in the action

# The result should be an (empty) list, but it is currently
# an exception saying that the action isn't in the state's
# list of actions.

$actions = join( ', ', $wf->get_current_actions(), '' );
ok( ( $actions =~ m/FORWARD,/ ),
    'FORWARD action is available in the original workflow' );
my $wfa = $factory->create_workflow('CachedCondition');
$wfa->context->param(alternative => 'yes');
$actions = join( ', ', $wfa->get_current_actions(), '' );
ok( ( $actions =~ m/FORWARD-ALT,/ ),
    'FORWARD-ALT action is available in the secondary workflow' );

lives_ok( sub { $wf->get_action_fields('FORWARD') },
          'Getting the fields on a valid action should' );
lives_ok( sub { $wf->execute_action('FORWARD') },
          'Executing the available forward state succeeds' );

is( $wf->state, 'SECOND',
    'The original workflow changed state successfully');
is( $wfa->state, 'INITIAL',
    'The secondary workflow is unaffected by changes to original');


