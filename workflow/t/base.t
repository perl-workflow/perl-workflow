# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 26;

require_ok( 'Workflow::Base' );

my $b = Workflow::Base->new();
is( ref( $b ), 'Workflow::Base',
    'Object created of correct type' );
is( ref $b->{PARAMS}, 'HASH',
    'Internal parameter storage created' );
is( scalar keys %{ $b->{PARAMS} }, 0,
    'No parameters set' );
my $b_hash = $b->param;
is( ref( $b_hash ), 'HASH',
    'All parameter call returns hashref' );
is( scalar keys %{ $b_hash }, 0,
    'No parameters set in all parameter call' );
is( $b->param( 'foo' ), undef,
    'Parameter call to nonexistent key returns undef' );
is( $b->param( foo => 'bar' ), 'bar',
    'Parameter call with single value set returns value' );
is( $b->param( 'foo' ), 'bar',
    'Parameter call to existent key returns proper value' );
my $b_all_hash = $b->param({ baz => 'quux', blah => 'blech' });
is( ref( $b_all_hash ), 'HASH',
    'Parameter call with multiple keys and values returns hashref' );
is( scalar keys %{ $b_all_hash }, 3,
    'Proper number of parameters after multiple values set' );
is( $b->param( 'baz' ), 'quux',
    'Multiple parameter set value 1 ok' );
is( $b->param( 'blah' ), 'blech',
    'Multiple parameter set value 2 ok' );
is( $b->delete_param('baz'), 'quux',
    'Delete one parameter' );
is( $b->param( 'baz' ), undef,
    'Parameter call to nonexistent key returns undef' );
my $list = $b->delete_param(['blah']);
is ( $list->{'blah'}, 'blech',
    'Deleted several parameters' );
is( $b->param( 'blah' ), undef,
    'Parameter call to nonexistent key returns undef' );
ok( $b->clear_params,
    'Cleared param call executed ok' );
is( scalar keys %{ $b->param }, 0,
    'All parameters cleared' );

create_subclass();

my $b_params = My::Workflow::Base->new({
    param => [ { name => 'foo', value => 'bar' },
               { name => 'baz', value => 'quux' } ],
    green => 'grimy gophers',
});
is( ref( $b_params ), 'My::Workflow::Base',
    'Constructor using multiple generic params returned correct subclass' );
is( $b_params->param( 'foo' ), 'bar',
    'Generic param value 1 (set via init()) ok' );
is( $b_params->param( 'baz' ), 'quux',
    'Generic param value 2 (set via init()) ok' );
is( $b_params->param( 'green' ), 'grimy gophers' ,
    'Named param value (set via init()) ok' );

my @no_items   = $b_params->normalize_array();
is( scalar @no_items, 0,
    'Empty array normalized to empty array' );
my @list_items = $b_params->normalize_array( 'foo' );
is( scalar @list_items, 1,
    'List of one item normalized to array of proper size' );
my @ref_items  = $b_params->normalize_array( [ 'foo', 'bar', 'baz' ] );
is( scalar @ref_items, 3,
    'List reference normalized to array of proper size' );


# Test out 'init()' call of subclass

sub create_subclass {
    my $subclass = <<'SUBCLASS';
package My::Workflow::Base;

use strict;
use base qw( Workflow::Base );

sub init {
    my ( $self, $params ) = @_;
    while ( my ( $k, $v ) = each %{ $params } ) {
        $self->param( $k => $v );
    }
}

1;
SUBCLASS
    eval $subclass;
    if ( $@ ) {
        die "Cannot eval subclass on the fly: $@";
    }
}
