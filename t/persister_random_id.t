# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::More tests => 10;

require_ok( 'Workflow::Persister::RandomId' );
my $generator = Workflow::Persister::RandomId->new();
is( ref( $generator ), 'Workflow::Persister::RandomId',
    'Object created of correct type' );
is( $generator->id_length, 8,
    'Default length of ID set properly' );
my $id_one = $generator->pre_fetch_id;
ok( $id_one,
    'Value returned from generator' );
is( length( $id_one ), 8,
    '...and of correct length' );
my $id_two = $generator->pre_fetch_id;
is( length( $id_one ), 8,
    'Separate value returned from generator also of correct length' );
ok( $id_one ne $id_two,
    'Two generated IDs not equal (good)' );
is( $generator->post_fetch_id, undef,
    'Nothing returned from post_fetch method (good)' );

my $generator_long = Workflow::Persister::RandomId->new({ id_length => 36 });
is( $generator_long->id_length, 36,
    'Explicit ID length set properly' );
my $id_long = $generator_long->pre_fetch_id;
is( length( $id_long ), 36,
    'Value returned from generator correct length' );


