package Workflow::Condition::IsTrue;

use warnings;
use strict;

use parent qw(Workflow::Condition::Result);

$Workflow::Condition::IsTrue = '2.06';

1;

__END__

=pod

=head1 NAME

Workflow::Condition::IsTrue - helper class for true conditions

=head1 VERSION

This documentation describes version 2.06 of this package

=head1 SYNOPSIS

    if (ref $result eq 'Workflow::Condition::IsTrue') {
        ...
    }

=head1 DESCRIPTION

This is a helper class, based on L<Workflow::Condition::Result>.

=head1 SEE ALSO

=over

=item * L<Workflow::Condition>

=item * L<Workflow::Condition::Result>

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
