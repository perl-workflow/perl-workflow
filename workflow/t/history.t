# -*-perl-*-

# $Id$

use strict;
use Test::More  tests => 10;

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
