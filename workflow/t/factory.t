# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 5;

require_ok( 'Workflow::Factory' );

my $factory = Workflow::Factory->instance();
is( ref( $factory ), 'Workflow::Factory',
    'Return from instance() correct type' );
my $other_factory = Workflow::Factory->instance();
is( $other_factory, $factory,
    'Another call to instance() returns same object' );
my $factory_new = eval { Workflow::Factory->new() };
is( ref( $@ ), 'Workflow::Exception',
    'Call to new() throws proper exception' );

my $i_factory = Workflow::Factory->import( 'FACTORY' );
is( $i_factory, $factory,
    'Imported factory returns the same object' );

