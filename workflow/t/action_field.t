# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::Exception;
use Test::More  tests => 16;

require_ok( 'Workflow::Action::InputField' );

my $action;

dies_ok { $action = Workflow::Action::InputField->new({}) };

ok($action = Workflow::Action::InputField->new({
    name        => 'test',
    is_required => 'yes', 
}));

isa_ok($action, 'Workflow::Action::InputField');

my @values;

@values = $action->get_possible_values();

is(scalar @values, 0);

ok(@values = $action->add_possible_values(
    { label => 'foo', value => '1' },
    { label => 'bar', value => '2' },
));

ok(@values = $action->get_possible_values());

is(scalar @values, 2);

is($action->is_required, 'yes');

is($action->is_optional, 'no');

ok($action = Workflow::Action::InputField->new({
    name        => 'test',
    is_required => 'no', 
}));

is($action->is_required, 'no');

is($action->is_optional, 'yes');

ok($action = Workflow::Action::InputField->new({
    name        => 'test',
}));

is($action->is_required, 'no');

is($action->is_optional, 'yes');
