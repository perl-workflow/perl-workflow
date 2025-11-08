package Workflow::Condition::Result;

use warnings;
use strict;

use parent qw( Class::Accessor );

use overload '""' => 'to_string';

__PACKAGE__->mk_accessors('message');

$Workflow::Condition::Result = '2.07';

sub new {
    my ( $class, @params ) = @_;
    my $self = bless { }, $class;
    $self->message( shift @params ) if (@params);
    return $self;
}

sub to_string {
    my $self = shift;
    return $self->message() || '<no message>';
}

1;

__END__

=pod

=head1 NAME

Workflow::Condition::Result - Base class for condition results isTrue and isFalse

=head1 VERSION

This documentation describes version 2.07 of this package

=head1 SYNOPSIS

    package Workflow::Condition::IsFalse;

    use parent qw(Workflow::Condition::Result);

=head1 DESCRIPTION

Base class for condition results L<Workflow::Condition::IsTrue> and L<Workflow::Condition::IsFalse>.

=head1 METHODS

=head2 Class Methods

=head3 to_string

Returns the message of the result object or the string '<no message>' if no message is set.

=head1 SEE ALSO

=over

=item * L<Workflow::Condition>

=item * L<Workflow::Condition::IsTrue>

=item * L<Workflow::Condition::IsFalse>

=back

=head1 COPYRIGHT

Copyright (c) 2004-2024 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
