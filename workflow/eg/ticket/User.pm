package User;

# $Id$

use strict;
use base qw( Class::Accessor );

$User::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( id name );
__PACKAGE__->mk_accessors( @FIELDS );

sub new {
    my ( $class, %params ) = @_;
    return bless( \%params, $class );
}

1;
