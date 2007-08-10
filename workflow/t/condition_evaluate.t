# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 4;

my $wf;

require_ok( 'Workflow::Condition::Evaluate' );

ok(my $condition = Workflow::Condition::Evaluate->new( test => '' ));

isa_ok($condition, 'Workflow::Condition::Evaluate');

ok($condition->evaluate($wf));
