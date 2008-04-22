package App::Condition::IsWorker;

# $Id$

use strict;
use base qw( Workflow::Condition );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( condition_error );
use Workflow::Factory   qw( FACTORY );

$App::Condition::IsWorker::VERSION = '1.02';

my ( $log );

sub evaluate {
    my ( $self, $wf ) = @_;
    $log ||= get_logger();
    $log->debug( "Trying to execute condition ", ref( $self ) );
    my $cond_has_info = FACTORY->get_condition( 'HasUserAndTicket' );
    $cond_has_info->evaluate( $wf );
    my $cond_creator = FACTORY->get_condition( "IsCreator" );
    eval { $cond_creator->evaluate( $wf ) };
    unless ( $@ ) {
        condition_error "Current user is a creator";
    }
}

1;
