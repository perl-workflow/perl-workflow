package Workflow::Condition::HasUser;

# $Id$

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );

$Workflow::Condition::HasUser::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my $DEFAULT_USER_KEY = 'current_user';

sub _init {
    my ( $self, $params ) = @_;
    my $key_name = $params->{user_key} || $DEFAULT_USER_KEY;
    $self->param( user_key => $key_name );
}

sub evaluate {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->debug( "Trying to execute condition ", ref( $self ) );
    my $user_key = $self->param( 'user_key' );
    my $current_user = $wf->context->param( $user_key );
    $log->debug( "Current user in the context is '$current_user' retrieved ",
                 "using parameter key '$user_key'" );
    unless ( $current_user ) {
        condition_error "No 'current_user' available";
    }
}

1;
