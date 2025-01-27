package App::Condition::HasUserAndTicket;



use strict;
use parent qw( Workflow::Condition );
use Log::Any qw( $log );
use Workflow::Condition::IsFalse;
use Workflow::Condition::IsTrue;

$App::Condition::HasUserAndTicket::VERSION = '1.02';

sub evaluate {
    my ( $self, $wf ) = @_;

    my $current_user = $wf->context->param( 'current_user' );
    my $ticket = $wf->context->param( 'ticket' );
    $log->info( "[Current user: $current_user] [Ticket: $ticket]" );
    unless ( $current_user and $ticket ) {
         return Workflow::Condition::IsFalse->new();
    }
    return Workflow::Condition::IsTrue->new();
}

1;
