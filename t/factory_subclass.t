#!/usr/bin/env perl

use strict;
use lib qw(t);
use TestUtil;
use Test::More  tests => 5;

no warnings 'once';
require Log::Log4perl;
Log::Log4perl::easy_init($Log::Log4perl::OFF);


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

my $i_factory = FactorySubclass->import( 'FACTORY' );
is( $i_factory, $factory,
    'Imported factory returns the same object' );

