package Workflow::Condition::Nested;

=head1 NAME

Workflow::Condition::Nested - Evaluate nested workflow conditions

=head1 DESCRIPTION

Typically, the workflow conditions are evaluated directly by the framework
in Workflow::State when the action is evaluated. This module allows
a workflow condition to contain nested conditions that are evaluated
directly rather than via separate workflow actions.

This allows the workflow to be designed to group multiple conditions
and perform advanced  operations like an OR comparision of multiple
conditions with "greedy" evaluation (as opposed to "lazy" evaluation).

A usage example might be a case where 3 of 5 possible approvals are needed
for an action to be allowed. The "Greedy OR" condition would define the
list of conditions to be evaluated. After checking each condition, it would
return the total number of successes. The result is then checked against
the number needed, returning the boolean value needed by Workflow::State.

B<Note:> This class is not used directly, but subclassed by your class
that implements the C<evaluate()> method and calls methods declared here.

=head1 SYNOPSIS

In condition.xml:

    <condition name="cond1" ... />
    <condition name="cond2" ... />
    <condition name="cond3" ... />
    <condition name="cond4" ... />
    <condition name="cond5" ... />

    <condition name="count_approvals" class="Workflow::Condition::GreedyOR">
        <param name="condition" value="cond1" />
        <param name="condition" value="cond2" />
        <param name="condition" value="cond3" />
        <param name="condition" value="cond4" />
        <param name="condition" value="cond5" />
    </condition>

    <condition name="check_approvals" class="Workflow::Condition::CheckReturn">
        <param name="condition" value="count_approvals" />
        <!-- operator "ge" means: greater than or equal to -->
        <param name="operator"  value="ge" />
        <param name="argument"  value="$context->{approvals_needed}" />
    </condition>

In workflow.xml:

    <state name="CHECK_APPROVALS" autorun="yes">
        <action name="null_1" resulting_state="APPROVED">
            <condition name="check_approvals" />
        </action>
        <action name="null_2" resulting_state="REJECTED">
            <condition name="!check_approvals" />
        </action>
    </state>

=cut

use strict;
use warnings;

use base qw( Workflow::Condition );
use Workflow::Factory qw( FACTORY );
use English qw( -no_match_vars );
use Log::Log4perl qw( get_logger );

my ($log);

=head1 IMPLEMENTATION DETAILS

This wicked hack runs the condition half-outside of the Workflow framework.
If the Workflow internals change, this may break.

=head2 $self->evaluate_condition( $WORKFLOW, $CONDITION_NAME )

The child object class that subclasses this object calls
this method to evaluate a nested condition.

=cut

sub evaluate_condition {
    my ( $self, $wf, $condition_name ) = @_;
    $log ||= get_logger();

    my $factory;
    if ( $wf->can('_factory') ) {
        $factory = $wf->_factory();
    }
    else {
        $factory = FACTORY;
    }

    my $condition;

    my $orig_condition = $condition_name;
    my $opposite       = 0;

    $log->is_debug
        && $log->debug("Checking condition $condition_name");

=pod

If the condition name starts with an '!', the result of the condition
is negated. Note that a side-effect of this is that the return
value of the nested condition is ignored. Only the negated boolean-ness
is preserved.

=cut

    if ( $condition_name =~ m{ \A ! }xms ) {

        $orig_condition =~ s{ \A ! }{}xms;
        $opposite = 1;
        $log->is_debug
            && $log->debug("Condition starts with a !: '$condition_name'");
    }

    # NOTE: CACHING IS NOT IMPLEMENTED/TESTED YET

    $condition = $factory->get_condition( $orig_condition, $wf->type() );

=pod

This does implement a trick that is not a convention in the underlying
Workflow library. By default, workflow conditions throw an error when
the condition is false and just return when the condition is true. To
allow for counting the true conditions, we also look at the return
value here. If a condition returns zero or an undefined value, but
did not throw an exception, we consider it to be '1'. Otherwise, we
consider it to be the value returned.

=cut

    my $result;
    $log->is_debug
        && $log->debug( q{Evaluating condition '}, $condition->name, q{'} );
    eval { $result = $condition->evaluate($wf) };
    if ($EVAL_ERROR) {

        # TODO: We may just want to pass the error up without wrapping it...
        $factory->{'_condition_result_cache'}->{$orig_condition} = 0;
        if ( !$opposite ) {
            $log->is_debug
                && $log->debug("Condition '$condition_name' failed");
            return 0;
        }
        else {
            $log->is_debug
                && $log->debug("Condition '$condition_name' failed, but result is negated");
            return 1;
        }
    }
    else {
        $factory->{'_condition_result_cache'}->{$orig_condition} = $result
            || 1;
        if ($opposite) {
            $log->is_debug
                && $log->debug("Condition '$condition_name' OK, but result is negated");
            return 0;
        }
        else {
            $log->is_debug
                && $log->debug(" Condition '$condition_name' OK and not negated");

            # If the condition returned nothing, bump it to 1
            return $result || 1;
        }
    }
}

1;
