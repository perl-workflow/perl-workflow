# -*-perl-*-

# $Id$

use strict;
use Test::More  tests => 5;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init({ level => $WARN,
                           file  => ">> workflow_tests.log" });

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

