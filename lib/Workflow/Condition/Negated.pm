package Workflow::Condition::Negated;

use strict;
use warnings;

our $VERSION = '1.57';

use base qw( Workflow::Condition );

my @FIELDS = qw( name class negated );
__PACKAGE__->mk_accessors(@FIELDS);

sub _init {
    my ( $self, $params ) = @_;
    my $negated = $params->{name};
    $negated =~ s/ \A ! //gx;
    $self->negated( $negated );
    $self->SUPER::_init($params);
}

sub evaluate {
    my ($self, $wf) = @_;
    return not $self->evaluate_condition($wf, $self->negated);
}


1;

__END__

=pod

=head1 NAME

Workflow::Condition::Negated - Negate workflow condition result

=head1 VERSION

This documentation describes version 1.57 of this package

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
