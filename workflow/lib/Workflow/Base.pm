package Workflow::Base;

# $Id$

use strict;
use base qw( Class::Accessor );
use Log::Log4perl;

$Workflow::Base::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub new {
    my ( $class, @params ) = @_;
    my $self = bless( { PARAMS => {} }, $class );
    $self->init( @params );
    return $self;
}

sub init { return }

sub param {
    my ( $self, $name, $value ) = @_;
    unless ( $name ) {
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

=head1 DESCRIPTION

=head1 CLASS METHODS

=head1 OBJECT METHODS

=head1 SEE ALSO

