# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 18;

require_ok( 'Workflow::History' );

my %params = (
    workflow_id => 5,
    action      => 'An action',
    description => 'A description',
    user        => 'Racer X',
    state       => 'TRANSIT',
    date        => DateTime->now(),
);
my $p_history = Workflow::History->new( \%params );
for ( keys %params ) {
    is( $p_history->$_(), $params{ $_ },
        "Parameter '$_' set properly from constructor" );
}
is( $p_history->is_saved, 0,
    "Saved flag of new object unset" );
ok( ! $p_history->id,
    "ID of new object unset" );

my $dt_history = Workflow::History->new();
ok( $dt_history->date->epoch + 10 > time,
    'Current datetime set with new history object' );

my $history;

ok($history = Workflow::History->new({}), 'Constructing history object');

isa_ok($history, 'Workflow::History');

ok(! $history->is_saved(), 'Checking saved state');

ok($history->set_new_state('foo'), 'Setting state');

ok($history->set_saved(), 'Setting saved state');

ok($history->is_saved(), 'Checking saved state');

ok(! $history->clear_saved(), 'Unsetting saved state');

ok(! $history->is_saved(), 'Checking saved state');
