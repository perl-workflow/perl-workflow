#!/usr/bin/env perl

use strict;
use lib 't/lib';
use TestUtil;
use Test::More  tests => 1;

no warnings 'once';


require_ok( 'Workflow::Validator::HasRequiredField' );
