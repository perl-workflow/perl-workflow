#!/usr/bin/perl

use strict;
use WorkflowFactory;

# This step is normally centralized, similar to OI2::Context...

my $wf_factory = WorkflowFactory->initialize(
                         { workflow_init  => 'workflow.ini',
                           action_init    => 'workflow_action.ini',
                           validator_init => 'workflow_validator.ini',
                           condition_init => 'workflow_condition.ini' });

# Create a new workflow and save it.

my $wf = $wf_factory->new_workflow();
print "Current state: ", $wf->current_state, "\n";
my @actions = $wf->available_actions;
print "Actions available in the current environment: \n";
foreach my $action ( @actions ) {
    print "   ", $action->name, " - ", $action->description, "\n";
}
$wf->save();

# You'd associate the workflow with an object (like a ticket) by
# getting its ID

print "Workflow saved with ID: ", $wf->id;
$ticket->workflow_id( $wf->id );
$ticket->save();

# Fetch an existing workflow with ID 55

my $wf = $wf_factory->fetch_workflow( 55 );
$wf->execute_action( 'TIX_NEW' );
$wf->save();
