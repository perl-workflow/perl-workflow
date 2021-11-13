#!/usr/bin/env perl

use strict;
use lib qw(t);
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

lives_ok { $factory->add_config_from_file( workflow  => 't/workflow.xml',
                                    action    => [ 't/workflow_action.xml', 't/workflow_action_type.xml', 't/workflow_action.perl',  ],
                                    validator => [ 't/workflow_validator.xml', 't/workflow_validator.perl' ],
                                    condition => 't/workflow_condition.xml') };

lives_ok { $factory->add_config_from_file( workflow  =>  [ 't/workflow.xml', 't/workflow.perl' ],
                                    action    => 't/workflow_action.xml',
                                    validator => 't/workflow_validator.xml',
                                    condition => [ 't/workflow_condition.xml', 't/workflow_condition.perl' ]) };
