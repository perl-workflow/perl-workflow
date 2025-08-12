#!/usr/bin/env perl

use strict;
use lib 't/lib';
use TestUtil;
use Test::More tests => 7;
use Test::Exception;

require_ok( 'Workflow::Factory' );

my $factory = Workflow::Factory->instance();
my $wf;

lives_ok { TestUtil->init_mock_persister }
  'Loading test persister succeeds';

dies_ok { $wf = $factory->create_workflow( 'CallbackTest' ) }
  'Attempt to create new workflow without loading its config first dies';

can_ok( $factory, 'config_callback' );

lives_ok {
    $factory->config_callback(
        sub {
            my $type = shift;
            if ($type eq 'CallbackTest') {
                return {
                    workflow  => 't/workflow_callback.d/workflow_callback.xml',
                    action    => 't/workflow_callback.d/workflow_action_callback.xml',
                    condition => 't/workflow_callback.d/workflow_condition_callback.xml' };
            }
            return {};
        } )
} 'Setting callback function succeeds';

dies_ok { $wf = $factory->create_workflow( 'CallbackTestBogus' ) }
  'Attempt to create unknown workflow still dies';

lives_ok { $wf = $factory->create_workflow( 'CallbackTest' ) }
  'Attempt to create known workflow via callback succeeds';
