package App::Condition::IsWorker;



use strict;
use parent qw( Workflow::Condition );
use Log::Any            qw( $log );
use Workflow::Condition::IsFalse;
use Workflow::Condition::IsTrue;
use Workflow::Factory   qw( FACTORY );

$App::Condition::IsWorker::VERSION = '1.02';

sub evaluate {
    my ( $self, $wf ) = @_;

    $log->debug( "Trying to execute condition ", ref( $self ) );
    my $cond_has_info = FACTORY->get_condition( 'HasUserAndTicket' );
    $cond_has_info->evaluate( $wf );
    my $cond_creator = FACTORY->get_condition( "IsCreator" );
    eval { $cond_creator->evaluate( $wf ) };
    unless ( $@ ) {
        return Workflow::Condition::IsFalse->new();
    }
    return Workflow::Condition::IsTrue->new();
}

1;
