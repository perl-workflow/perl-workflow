package Workflow::Persister::UUID;

# $Id$

use strict;
use Data::UUID;

$Workflow::Persister::UUID::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
    my ( $class, $params ) = @_;
    my $self = bless( { gen => Data::UUID->new() }, $class );
    return $self;
}

sub pre_fetch_id {
    my ( $self, $dbh ) = @_;
    return $self->{gen}->create_str();
}

sub post_fetch_id { return }

1;

__END__

=head1 NAME

Workflow::Persister::UUID - Persister to generate Universally Unique Identifiers

=head1 SYNOPSIS

 <persister
     name="MyPersister"
     use_uuid="yes"
 ...

=head1 DESCRIPTION

Implementation for any persister to generate a UUID/GUID ID
string. The resulting string is 36 characters long and, according to
the implementation docs, "is guaranteed to be different from all other
UUIDs/GUIDs generated until 3400 CE."

This uses the L<Data::UUID> module to generate the UUID string, so
look there if you are curious about the algorithm, efficiency, etc.

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
