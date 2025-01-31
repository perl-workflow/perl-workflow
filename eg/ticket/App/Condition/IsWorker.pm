package App::Condition::IsWorker;



use strict;
use parent qw( Workflow::Condition );
use Log::Any            qw( $log );
use Workflow::Condition::IsFalse;
use Workflow::Condition::IsTrue;

$App::Condition::IsWorker::VERSION = '1.02';

sub evaluate {
    my ( $self, $wf ) = @_;

    $log->debug( "Trying to execute condition ", ref( $self ) );
    unless ($self->evaluate_condition( $wf, 'HasUserAndTicket' )
            and $self->evaluate_condition( $wf, 'IsCreator' )) {
        return Workflow::Condition::IsFalse->new();
    }
    return Workflow::Condition::IsTrue->new();
}

1;
