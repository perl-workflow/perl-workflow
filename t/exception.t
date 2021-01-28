#!/usr/bin/env perl

use strict;
use lib qw(../lib lib ../t t);
use TestUtil;
use Test::More  tests => 1;

require_ok( 'Workflow::Exception' );
