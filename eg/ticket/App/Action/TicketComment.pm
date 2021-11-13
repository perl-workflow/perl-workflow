package App::Action::TicketComment;

use strict;
use parent qw( Workflow::Action );
use Log::Any qw( $log );

$App::Action::TicketComment::VERSION = '1.03';

sub execute {
    my ( $self, $wf ) = @_;

    $log->info( "Entering comment for workflow ", $wf->id );

    $wf->add_history(
        Workflow::History->new({
            action      => "Ticket comment",
            description => $wf->context->param( 'comment' ),
            user        => $wf->context->param( 'current_user' ),
        })
    );
}

1;
