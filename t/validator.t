# -*-perl-*-

# $Id$

use strict;
use lib qw(../lib lib ../t t);
use TestUtil;
use Test::More  tests => 2;
use Test::Exception;

require_ok( 'Workflow::Validator' );

dies_ok { Workflow::Validator->validate(); };
