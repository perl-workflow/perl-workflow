package TestCachedApp::Condition::EvenCounts;

use strict;
use parent qw( Workflow::Condition );

use Log::Any qw( $log );


our $count = 0;

sub evaluate {
    my ( $self, $wf ) = @_;
    $log->debug(__PACKAGE__, '::evaluate(', $count, ')');
    if ((($count++) >> 1) % 2 == 0) {
        # the condition is a bit tricky here:
        #  because the condition is evaluated twice, we need to return
        #  the same result twice: the first time on 'get_current_actions'
        #  and the second time on 'execute_action'
        $log->debug(__PACKAGE__, '::evaluate(', $count, '): fail');
        return Workflow::Condition::IsFalse->new();
    }
    $log->debug(__PACKAGE__, '::evaluate(', $count, '): success');

    return Workflow::Condition::IsTrue->new();

}

1;
