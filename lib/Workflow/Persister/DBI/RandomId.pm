package Workflow::Persister::DBI::RandomId;

# $Id$

use strict;
use base qw( Class::Accessor );

$Workflow::Persister::DBI::RandomId::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( id_length );
__PACKAGE__->mk_accessors( @FIELDS );

sub new {
    my ( $class, $params ) = @_;
    my $self = bless( {}, $class );
    my $length = $params->{id_length} || 8;
    $self->id_length( $length );
    return $self;
}

sub pre_fetch_id {
    my ( $self, $dbh ) = @_;
    return join( '', map { chr( int( rand(26) ) + 65 ) } ( 1 .. $self->id_length ) );
}

sub post_fetch_id { return }

1;

__END__

=head1 NAME

Workflow::Persister::DBI::RandomId - Persister to generate random ID

=head1 SYNOPSIS

 <persister
     name="MyPersister"
     id_length="16"
 ...

=head1 DESCRIPTION

Implementation for DBI persister to generate a random ID string. You
can specify the length using the 'id_length' parameter, but normally
the default (8 characters) is sufficient.

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
