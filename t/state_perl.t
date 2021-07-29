#!/usr/bin/env perl

use strict;
use lib qw(../lib lib ../t t);
use TestUtil;
use Test::More  tests => 20;

require_ok( 'Workflow::State' );

my $factory;

# Run again with perl-based config.
$factory = TestUtil->init_factory_perl_config();
TestUtil->init_mock_persister();

TestUtil::run_state_tests($factory);
