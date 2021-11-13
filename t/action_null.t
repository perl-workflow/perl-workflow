#!/usr/bin/env perl

use strict;
use lib qw(t);
use TestUtil;
use Test::More  tests => 2;

require_ok( 'Workflow::Action::Null' );

ok(! Workflow::Action::Null->execute());
