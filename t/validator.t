#!/usr/bin/env perl

use strict;
use lib qw(t);
use TestUtil;
use Test::More  tests => 2;
use Test::Exception;

no warnings 'once';
require Log::Log4perl;
Log::Log4perl::easy_init($Log::Log4perl::OFF);


require_ok( 'Workflow::Validator' );

dies_ok { Workflow::Validator->validate(); };
