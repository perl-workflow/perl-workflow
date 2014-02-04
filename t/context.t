# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 9;
use Test::Exception;

require_ok( 'Workflow::Context' );

ok(my $context = Workflow::Context->new());

isa_ok($context, 'Workflow::Context');

ok($context->param( foo => 'bar' ));

is($context->param('foo'), 'bar');

my $other_context = Workflow::Context->new();

ok($other_context->param( argle => 'bargle' ));

is($other_context->param('argle'), 'bargle');

lives_ok { $context->merge($other_context); };

is($context->param('argle'), 'bargle');
   
   