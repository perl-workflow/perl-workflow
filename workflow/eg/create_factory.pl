#!/usr/bin/perl

use strict;
use lib qw( ../lib );
use Data::Dumper qw( Dumper );
use Log::Log4perl;
use WorkflowContext;
use WorkflowFactory;

$Data::Dumper::Indent = 1;

Log::Log4perl::init( 'log4perl.conf' );

my $factory = WorkflowFactory->new({ workflow_init  => 'workflow.ini',
                                     action_init    => 'workflow_action.ini',
                                     validator_init => 'workflow_validator.ini',
                                     condition_init => 'workflow_condition.ini' });
my $wf = $factory->get_workflow( 'Test' );

my $context = WorkflowContext->new;
$context->param( current_user => 'Chris' );
$wf->context( $context );

eval {
    $wf->execute_action( 'TIX_NEW' );
    print "New state of workflow after creation: ", $wf->state, "\n";
   $wf->execute_action( 'TIX_EDIT' );
    print "New state of workflow after starting edit: ", $wf->state, "\n";
};

if ( $@ ) {
    print "Cannot execute action: $@\n";
}

print "\n";
