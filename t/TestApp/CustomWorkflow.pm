package TestApp::CustomWorkflow;

use warnings;
use strict;
use v5.14.0;
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
