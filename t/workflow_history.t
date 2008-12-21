# -*-perl-*-

# $Id: validator_matches_date_format.t 326 2007-08-10 19:50:28Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::More tests => 9;

require_ok( 'Workflow::History' );

my $history;

ok($history = Workflow::History->new({}), 'Constructing history object');

isa_ok($history, 'Workflow::History');

ok(! $history->is_saved(), 'Checking saved state');

ok($history->set_new_state('foo'), 'Setting state');

ok($history->set_saved(), 'Setting saved state');

ok($history->is_saved(), 'Checking saved state');

ok(! $history->clear_saved(), 'Unsetting saved state');

ok(! $history->is_saved(), 'Checking saved state');
