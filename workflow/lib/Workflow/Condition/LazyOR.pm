package Workflow::Condition::LazyOR;

=head1 NAME

Workflow::Condition::LazyOR

=head1 DESCRIPTION

Using nested conditions (See Workflow::Condition::Nested), this evaluates
the given conditions using lazy-evaluation, returning I<true> at the first
nested condition that returns I<true>. If all nested conditions return
I<false>, LazyOR also returns I<false>.

=head1 SYNOPSIS

In condition.xml:

    <condition name="cond1" ... />
    <condition name="cond2" ... />
    <condition name="cond3" ... />

    <condition name="check_prereqs" class="Workflow::Condition::LazyOR">
        <param name="condition" value="cond1" />
        <param name="condition" value="cond2" />
        <param name="condition" value="cond3" />
    </condition>

In workflow.xml:

    <state name="CHECK_PREREQS" autorun="yes">
        <action name="null_1" resulting_state="HAVE_PREREQS">
            <condition name="check_prereqs" />
        </action>
        <action name="null_2" resulting_state="FAILURE">
            <condition name="!check_prereqs" />
        </action>
    </state>

=cut

=head1 PARAMETERS

The following parameters may be configured in the C<param> entity of the
condition in the XML configuration:

=head2 condition, conditionN

The condition parameter may be specified as either a list of repeating
entries E<or> with a unique integer appended to the E<condition> string:

    <param name="condition" value="first_condition_to_test" />
    <param name="condition" value="second_condition_to_test" />

E<or>

    <param name="condition1" value="first_condition_to_test" />
    <param name="condition2" value="second_condition_to_test" />

=cut

use strict;
use warnings;

use base qw( Workflow::Condition::Nested );
use Workflow::Exception qw( condition_error configuration_error );
use English qw( -no_match_vars );

__PACKAGE__->mk_accessors('conditions');

my ($log);

sub _init {
    my ( $self, $params ) = @_;

    # This is a tricky one. The admin may have configured this by repeating
    # the param name "condition" or by using unique names (e.g.: "condition1",
    # "condition2", etc.). We'll need to string these back together as
    # an array.
    # Yes, I know. The regex doesn't require the suffix to be numeric.
    my @conditions = ();
    foreach my $key ( sort grep {m/^condition/} keys %{$params} ) {
        push @conditions, $self->normalize_array( $params->{$key} );
    }
    $self->conditions( [@conditions] );

}

sub evaluate {
    my ( $self, $wf ) = @_;
    my $conditions = $self->conditions;

    my $total = 0;

    foreach my $cond ( @{$conditions} ) {
        my $result = $self->evaluate_condition( $wf, $cond );
        if ( $result ) {
            return $result;
        }
    }
    condition_error( "All nested conditions returned 'false'" );
}

1;
