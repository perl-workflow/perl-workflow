package App::Condition::HasUserAndTicket;

# $Id$

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );

$App::Condition::HasUserAndTicket::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub evaluate {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    my $current_user = $wf->context->param( 'current_user' );
    my $ticket = $wf->context->param( 'ticket' );
    unless ( $current_user and $ticket ) {
        condition_error "Values for 'current_user' and 'ticket' must be available";
    }
}

1;
