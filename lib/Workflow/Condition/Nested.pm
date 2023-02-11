package Workflow::Condition::Nested;

use strict;
use warnings;

our $VERSION = '1.62';

use base qw( Workflow::Condition );

1;

__END__

=pod

=head1 NAME

Workflow::Condition::Nested - Evaluate nested workflow conditions

=head1 VERSION

This documentation describes version 1.62 of this package

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
that implements the C<evaluate()> method and calls the C<evaluate_condition>
method to evaluate its nested conditions.

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

=head1 AUTHORS

See L<Workflow>

=head1 COPYRIGHT

Copyright (c) 2004-2023 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
