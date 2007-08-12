# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::Exception;
use Test::More  tests => 3;

require_ok( 'Workflow::Action' );

my $action;

dies_ok { $action = Workflow::Action->new({}) };

dies_ok { Workflow::Action->execute(); };

#ok($action = Workflow::Action->new({}));

#isa_ok($action, 'Workflow::Action');