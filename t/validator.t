#!/usr/bin/env perl

use strict;
use lib qw(lib t);
use TestUtil;
use Test::More  tests => 2;
use Test::Exception;

require_ok( 'Workflow::Validator' );

dies_ok { Workflow::Validator->validate(); };
