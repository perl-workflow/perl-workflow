package App::Condition::IsCreator;

# $Id$

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );
use Workflow::Factory   qw( FACTORY );

$App::Condition::IsCreator::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my ( $FACTORY );

sub evaluate {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Trying to execute condition ", ref( $self ) );
    my $cond_has_info = FACTORY->get_condition( 'HasUserAndTicket' );
    $cond_has_info->evaluate( $wf );
    my $current_user = $wf->context->param( 'current_user' );
    my $ticket       = $wf->context->param( 'ticket' );
    $log->debug( "Current user in the context is '", $current_user->id, "' ",
                 "ticket creator is '", $ticket->creator_id, "'" );
    unless ( $ticket->creator_id eq $current_user->id ) {
        condition_error "User is not the creator of the ticket";
    }
}

1;
