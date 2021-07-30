#!/usr/bin/env perl

use strict;
use lib qw(t);
use TestUtil;
use Test::More  tests => 1;

require_ok( 'Workflow::Validator::HasRequiredField' );
