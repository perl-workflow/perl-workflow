package Workflow::Condition::HasUser;

# $Id$

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );

$Workflow::Condition::HasUser::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub evaluate {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Trying to execute condition ", ref( $self ) );
    my $current_user = $wf->context->param( 'current_user' );
    $log->debug( "Current user in the context is '$current_user'" );
    unless ( $current_user ) {
        condition_error "No 'current_user' available";
    }
}

1;
