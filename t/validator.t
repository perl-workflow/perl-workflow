#!/usr/bin/env perl

use strict;
use lib 't/lib';
use TestUtil;
use Test::More  tests => 2;
use Test::Exception;

no warnings 'once';


require_ok( 'Workflow::Validator' );

dies_ok { Workflow::Validator->validate(); };
