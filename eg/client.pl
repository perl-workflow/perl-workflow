#!/usr/bin/perl

use strict;
use WorkflowFactory;

my ( $id ) = @ARGV;
my $wf = WorkflowFactory->instance( 'MyClient' )->fetch( $id );
my $context = WorkflowContext->new();
$context->param( 'current_user', $user );
$context->param( 'current_group', \@groups );
$context->param( 'ticket', Ticket->fetch(55) );
$wf->context( $context );

$wf->execute_action( 'TIX_APPROVE' );

my $notified_users = $context->param( 'notified_users' );


# in the action
sub execute {
    # ...
    my @users = $ticket->get_administrators;
    $wf->context->param( 'notified_users', \@users );
}
