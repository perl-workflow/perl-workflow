package TestApp::Condition::HasUserType;



use strict;
use parent qw( Workflow::Condition );
use Log::Any qw( $log );

$TestApp::Condition::HasUserType::VERSION = '0.01';

sub evaluate {
    my ( $self, $wf ) = @_;
    $log->debug( "Trying to execute condition ", ref( $self ) );
    unless ( $wf->context->param( 'current_user' ) ) {
        return 0;
    }
    $log->debug( 'Condition met ok' );

    return Workflow::Condition::IsTrue->new();
}

1;
