#!/usr/bin/env perl

use strict;
use lib 't/lib';
use TestUtil;
use Test::More  tests => 4;

no warnings 'once';


require_ok( 'FactorySubclass' );
my $factory = FactorySubclass->instance();
is( ref( $factory ), 'FactorySubclass',
    "Return from subclassed instance() correct type" );
my $other_factory = FactorySubclass->instance();
is( $other_factory, $factory,
    'Another call to instance() returns same object' );
my $factory_new = eval { FactorySubclass->new() };
is( ref( $@ ), 'Workflow::Exception',
    'Call to new() throws proper exception' );

