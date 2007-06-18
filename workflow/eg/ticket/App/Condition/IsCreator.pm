package App::Condition::IsCreator;

# $Id$

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );
use Workflow::Factory   qw( FACTORY );

$App::Condition::IsCreator::VERSION = '1.02';

my ( $log );

my ( $FACTORY );

sub evaluate {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();
    $log->debug( "Trying to execute condition ", ref( $self ) );

    # First see that we have both a user and ticket...
    my $cond_has_info = FACTORY->get_condition( 'HasUserAndTicket' );
    $cond_has_info->evaluate( $wf );

    # ...then see that the user is the ticket creator (simple name match)
    my $current_user = $wf->context->param( 'current_user' );
    my $ticket       = $wf->context->param( 'ticket' );
    $log->debug( "Current user in the context is '", $current_user, "' ",
                 "ticket creator is '", $ticket->creator, "'" );
    unless ( $ticket->creator eq $current_user ) {
        condition_error "User is not the creator of the ticket";
    }
}

1;
