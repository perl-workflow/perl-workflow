package Workflow::Action::Mailer;

# $Id$

use warnings;
use strict;
use base qw( Workflow::Action );

$Workflow::Action::Mailer::VERSION = '1.01';

sub execute {
    my ($self) = @_;
    return 1;
}

1;

__END__

=head1 NAME

Workflow::Action::Mailer - a stub for a SMTP capable action

=head1 VERSION

This documentation describes version 1.01 of this package

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

Copyright (c) 2003-2007 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt> is the current maintainer.

Chris Winters E<lt>chris@cwinters.comE<gt>, original author.

=cut
