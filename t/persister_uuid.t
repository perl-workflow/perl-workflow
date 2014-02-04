# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;

use constant NUM_TESTS => 7;
use Test::More;

eval "require Data::UUID";
if ( $@ ) {
    plan skip_all => "Data::UUID not installed";
}

plan tests => NUM_TESTS;

require_ok( 'Workflow::Persister::UUID' );
my $generator = Workflow::Persister::UUID->new();
is( ref( $generator ), 'Workflow::Persister::UUID',
    'Object created of correct type' );
is( ref( $generator->{gen} ), 'Data::UUID',
    'Embedded generator is correct type' );
my $uuid = $generator->pre_fetch_id;
ok( $uuid,
    'Value returned from generator' );
is( length( $uuid ), 36,
    'Value returned from generator correct length' );
my $uuid_two = $generator->pre_fetch_id;
ok( $uuid ne $uuid_two,
    'Two UUIDs not equal (good)' );
is( $generator->post_fetch_id, undef,
    'Nothing returned from post_fetch method (good)' );
