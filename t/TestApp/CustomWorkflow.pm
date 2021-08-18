package TestApp::CustomWorkflow;

use warnings;
use strict;
use 5.006;
use parent qw( Workflow );

$TestApp::CustomWorkflow::VERSION = '0.01';


sub get_initial_history_data {
    return (
        user => 'me',
        description => 'New workflow',
        action => 'Create',
    );
}

1;
