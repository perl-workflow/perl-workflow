#!/usr/bin/env perl

use strict;
use lib 't/lib';
use TestUtil;
use Test::More  tests => 6;
use Test::Exception;

no warnings 'once';


require_ok( 'Workflow::Factory' );

my $factory = Workflow::Factory->instance();
is( ref( $factory ), 'Workflow::Factory',
    'Return from instance() correct type' );
my $other_factory = Workflow::Factory->instance();
is( $other_factory, $factory,
    'Another call to instance() returns same object' );
my $factory_new = eval { Workflow::Factory->new() };
is( ref( $@ ), 'Workflow::Exception',
    'Call to new() throws proper exception' );

lives_ok {
    $factory->add_config_from_file(
        workflow  => 't/workflow.d/workflow.xml',
        action    => [
            't/workflow.d/workflow_action.xml',
            't/workflow.d/workflow_action.perl',
            't/workflow_type.d/workflow_action_type.xml',
        ],
        validator => [
            't/workflow.d/workflow_validator.xml',
            't/workflow.d/workflow_validator.perl'
        ],
        condition => 't/workflow.d/workflow_condition.xml' )
};

lives_ok {
    $factory->add_config_from_file(
        workflow  =>  [
            't/workflow.d/workflow.xml',
            't/workflow.d/workflow.perl'
        ],
        action    => 't/workflow.d/workflow_action.xml',
        validator => 't/workflow.d/workflow_validator.xml',
        condition => [
            't/workflow.d/workflow_condition.xml',
            't/workflow.d/workflow_condition.perl'
        ])
};
