# -*-perl-*-

# $Id$

use strict;
use Test::More  tests => 1;

use Log::Log4perl qw( :easy );
Log::Log4perl->easy_init({ level => $WARN,
                           file  => ">> workflow_tests.log" });

require_ok( 'Workflow::State' );
