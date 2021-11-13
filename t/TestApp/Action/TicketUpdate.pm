package TestApp::Action::TicketUpdate;

use strict;
use parent qw( Workflow::Action );
use Log::Any qw( $log );

$TestApp::Action::TicketUpdate::VERSION = '1.05';

sub execute {
    my ( $self, $wf ) = @_;

    $log->debug( "Action '", $self->name, "' with class '", ref( $self ), "' executing..." );
    my $ticket = $wf->context->param( 'ticket' );
    $ticket->status( $wf->state );
    $ticket->update;
}

1;
