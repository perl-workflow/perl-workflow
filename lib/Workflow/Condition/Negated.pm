package Workflow::Condition::Negated;

use warnings;
use strict;
use v5.14.0;

our $VERSION = '2.03';

use parent qw( Workflow::Condition );

my @FIELDS = qw( name class negated );
__PACKAGE__->mk_accessors(@FIELDS);

sub init {
    my ( $self, $params ) = @_;
    my $negated = $params->{name};
    $self->SUPER::init( $params );

    $negated =~ s/ \A ! //gx;
    $self->negated( $negated );
}

sub evaluate {
    my ($self, $wf) = @_;
    if ($self->evaluate_condition($wf, $self->negated)) {
        return Workflow::Condition::IsFalse->new();
    } else {
        return Workflow::Condition::IsTrue->new();
    }
}


1;

__END__

=pod

=head1 NAME

Workflow::Condition::Negated - Negate workflow condition result

=head1 VERSION

This documentation describes version 2.03 of this package

=head1 DESCRIPTION

This class is used by C<Workflow::State> to handle I<negated conditions>:
conditions of which the referring name starts with an exclamation mark (!).

Such conditions refer to another condition (by the name after the '!') and
return the negated result of the condition referred to (true becomes false
while false becomes true).

=head1 SYNOPSIS

In condition.xml:

    <condition name="check_approvals" class="...">
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

Copyright (c) 2004-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
