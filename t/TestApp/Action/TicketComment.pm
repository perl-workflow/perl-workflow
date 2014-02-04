package TestApp::Action::TicketComment;

# $Id$

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );

$TestApp::Action::TicketComment::VERSION  = '1.02';

sub execute {
    my ( $self, $wf ) = @_;
    my $log = get_logger();

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
