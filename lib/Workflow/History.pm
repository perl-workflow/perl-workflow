package Workflow::History;

# $Id$

use strict;
use base qw( Class::Accessor );

$Workflow::History::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( id date username user_id state description );
__PACKAGE__->mk_accessors( @FIELDS );

sub is_saved {
    return $self->id;
}

1;

__END__

=head1 NAME

Workflow::History - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASS METHODS

=head1 OBJECT METHODS

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
