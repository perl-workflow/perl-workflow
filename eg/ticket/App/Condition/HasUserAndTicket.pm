package App::Condition::HasUserAndTicket;



use strict;
use base qw( Workflow::Condition );
use Log::Any qw( $log );
use Workflow::Exception qw( condition_error );

$App::Condition::HasUserAndTicket::VERSION = '1.02';

sub evaluate {
    my ( $self, $wf ) = @_;

    my $current_user = $wf->context->param( 'current_user' );
    my $ticket = $wf->context->param( 'ticket' );
    $log->info( "[Current user: $current_user] [Ticket: $ticket]" );
    unless ( $current_user and $ticket ) {
        condition_error "Values for 'current_user' and 'ticket' must be available";
    }
}

1;
