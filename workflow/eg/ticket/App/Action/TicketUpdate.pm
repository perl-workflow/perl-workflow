package App::Action::TicketUpdate;

# $Id$

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );
use Workflow::History;

$App::Action::TicketUpdate::VERSION = '1.05';

sub execute {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Action '", $self->name, "' with class ",
                 "'", ref( $self ), "' executing..." );
    my $ticket = $wf->context->param( 'ticket' );
    $ticket->status( $wf->state );
    $ticket->update;

    my $current_user = $wf->context->param( 'current_user' );
    $wf->add_history(
        Workflow::History->new({
            action      => 'Ticket update',
            description => sprintf( 'Ticket updated by %s', $current_user ),
            user        => $current_user,
        })
    );
    $log->info( "History record added to workflow ok" );
}

1;
