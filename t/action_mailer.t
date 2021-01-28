#!/usr/bin/env perl

use strict;
use lib qw(../lib lib ../t t);
use TestUtil;
use Test::More  tests => 2;

require_ok( 'Workflow::Action::Mailer' );

ok(Workflow::Action::Mailer->execute());
