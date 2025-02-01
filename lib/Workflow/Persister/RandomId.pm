package Workflow::Persister::RandomId;

use warnings;
use strict;
use v5.14.0;
use parent qw( Class::Accessor );

use constant DEFAULT_ID_LENGTH  => 8;
use constant RANDOM_SEED        => 26;
use constant CONSTANT_INCREMENT => 65;

$Workflow::Persister::RandomId::VERSION = '2.05';

my @FIELDS = qw( id_length );
__PACKAGE__->mk_accessors(@FIELDS);

sub new {
    my ( $class, $params ) = @_;
    my $self = bless {}, $class;
    my $length = $params->{id_length} || DEFAULT_ID_LENGTH;
    $self->id_length($length);
    return $self;
}

sub pre_fetch_id {
    my ( $self, $dbh ) = @_;
    return join '',
        map { chr int( rand RANDOM_SEED ) + CONSTANT_INCREMENT }
        ( 1 .. $self->id_length );
}

sub post_fetch_id {return}

1;

__END__

=pod

=head1 NAME

Workflow::Persister::RandomId - Persister to generate random ID

=head1 VERSION

This documentation describes version 2.05 of this package

=head1 SYNOPSIS

 <persister
     name="MyPersister"
     id_length="16"
 ...

=head1 DESCRIPTION

Implementation for any persister to generate a random ID string. You
can specify the length using the 'id_length' parameter, but normally
the default (8 characters) is sufficient.

=head2 METHODS

=head3 new

Instantiates a Workflow::Persister::RandomId object, this object can generate
randon Id's based on the 'id_length' parameter provided. This parameter defaults
to 8.

=head3 pre_fetch_id

L</pre_fetch_id> can then be used to generate/retrieve a random ID, generated
adhering to the length specified in the constructor call.

=head3 post_fetch_id

This method is unimplemented at this time, please see the TODO.

=head1 TODO

=over

=item * Implement L</post_fetch_id>

=back

=head1 COPYRIGHT

Copyright (c) 2003-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
