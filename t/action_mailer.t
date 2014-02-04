# -*-perl-*-

# $Id: action_null.t 217 2004-12-09 16:02:45Z cwinters $

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 2;

require_ok( 'Workflow::Action::Mailer' );

ok(Workflow::Action::Mailer->execute());