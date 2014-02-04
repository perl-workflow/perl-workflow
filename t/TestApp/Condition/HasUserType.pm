package TestApp::Condition::HasUserType;

# $Id: HasUser.pm 290 2007-06-18 21:46:48Z jonasbn $

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );

$TestApp::Condition::HasUserType::VERSION = '0.01';

sub evaluate {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Trying to execute condition ", ref( $self ) );
    unless ( $wf->context->param( 'current_user' ) ) {
        condition_error "No value for 'current_user' set";
    }
    $log->debug( 'Condition met ok' );
}

1;
