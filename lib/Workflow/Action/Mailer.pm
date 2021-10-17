package Workflow::Action::Mailer;

use warnings;
use strict;
use base qw( Workflow::Action );

$Workflow::Action::Mailer::VERSION = '1.57';

sub execute {
    my ($self) = @_;
    return 1;
}

1;

__END__

=pod

=head1 NAME

Workflow::Action::Mailer - a stub for a SMTP capable action

=head1 VERSION

This documentation describes version 1.57 of this package

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 CLASS METHODS

=head2 OBJECT METHODS

=head3 execute

I<Currently a stub>

=head1 SEE ALSO

=over

=item L<Workflow>

=item L<Workflow::Action>

=back

=head1 COPYRIGHT

Copyright (c) 2003-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
