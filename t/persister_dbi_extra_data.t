#!/usr/bin/env perl

use strict;
use constant NUM_TESTS => 1;
use Test::More;
use lib qw(t);

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
}
plan tests => NUM_TESTS;

require_ok( 'Workflow::Persister::DBI::ExtraData' );
