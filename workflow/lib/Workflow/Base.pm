package Workflow::Base;

# $Id$

use strict;
use base qw( Class::Accessor );
use Log::Log4perl;

$Workflow::Base::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
    my ( $class, @params ) = @_;
    my $self = bless( { PARAMS => {} }, $class );

    # always automatically pull out the name/value pairs from 'param'

    if ( ref $params[0] eq 'HASH' && ref $params[0]->{param} eq 'ARRAY' ) {
        foreach my $declared ( @{ $params[0]->{param} }) {
            $params[0]->{ $declared->{name} } = $declared->{value};
        }
        delete $params[0]->{param};
    }
    $self->init( @params );
    return $self;
}

sub init { return }

sub param {
    my ( $self, $name, $value ) = @_;
    unless ( $name ) {
        return { %{ $self->{PARAMS} } };
    }

    # Allow multiple parameters to be set at once...

    if ( ref $name eq 'HASH' ) {
        foreach my $param_name ( keys %{ $name } ) {
            $self->{PARAMS}{ $param_name } = $name->{ $param_name };
        }
        return { %{ $self->{PARAMS} } };
    }

    unless ( $value ) {
        if ( exists $self->{PARAMS}{ $name } ) {
            return $self->{PARAMS}{ $name };
        }
        return undef;
    }
    return $self->{PARAMS}{ $name } = $value;
}

sub clear_params {
    my ( $self ) = @_;
    $self->{PARAMS} = {};
}

sub normalize_array {
    my ( $self, $ref_or_item ) = @_;
    return () unless ( $ref_or_item );
    return ( ref $ref_or_item eq 'ARRAY' )
             ? @{ $ref_or_item } : ( $ref_or_item );
}

1;

__END__

=head1 NAME

Workflow::Base - Base class with constructor

=head1 SYNOPSIS

 package My::App::Foo;
 use base qw( Workflow::Base );

=head1 DESCRIPTION

Provide a constructor and some other useful methods for subclasses.

=head1 METHODS

=head2 Class Methods

B<new( @params )>

Just create a new object (blessed hashref) and pass along C<@params>
to the C<init()> method, which subclasses can override to initialize
themselves.

Returns: new object

=head2 Object Methods

B<init( @params )>

Subclasses may implement to do initialization. The C<@params> are
whatever is passed into C<new()>. Nothing need be returned.

B<param( [ $name, $value ] )>

Associate arbitrary parameters with this object.

If neither C<$name> nor C<$value> given, return a hashref of all
parameters set in object:

 my $params = $object->param();
 while ( my ( $name, $value ) = each %{ $params } ) {
     print "$name = $params->{ $name }\n";
 }

If C<$name> given and it is a hash reference, assign all the values of
the reference to the object parameters. This is the way to assign
multiple parameters at once. Note that these will overwrite any
existing parameter values. Return a hashref of all parameters set in
object.

 $object->param({ foo => 'bar',
                  baz => 'blarney' });

If C<$name> given and it is not a hash reference, return the value
associated with it, C<undef> if C<$name> was not previously set.

 my $value = $object->param( 'foo' );
 print "Value of 'foo' is '$value'\n";

If C<$name> and C<$value> given, associate C<$name> with C<$value>,
overwriting any existing value, and return the new value.

 $object->param( foo => 'blurney' );

B<clear_params()>

Clears out all parameters associated with this object.

B<normalize_array( \@array | $item )>

If given C<\@array> return it dereferenced; if given C<$item>, return
it in a list. If given neither return an empty list.

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
