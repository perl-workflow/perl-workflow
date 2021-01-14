# -*-perl-*-

# $Id$

use strict;
use lib qw(../lib lib ../t t);
use TestUtil;
use Test::More  tests => 2;

require_ok( 'Workflow::Action::Null' );

ok(! Workflow::Action::Null->execute());
