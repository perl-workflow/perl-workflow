package TestApp::Action::TicketComment;

use strict;
use parent qw( Workflow::Action );
use Log::Any qw( $log );

$TestApp::Action::TicketComment::VERSION  = '1.02';

__PACKAGE__->mk_accessors(qw(index));

### Straight out of the Workflow::Action->init() documentation
sub init {
    my ($self, $wf, $params) = @_;
    $self->SUPER::init($wf, $params);
    $self->index($params->{index}) if defined $params->{index};
}

sub execute {
    my ( $self, $wf ) = @_;

    $log->info( "Entering comment for workflow ", $wf->id );

    $wf->add_history(
        {
            action      => "Ticket comment",
            description => $wf->context->param( 'comment' ),
            user        => $wf->context->param( 'current_user' ),
        }
    );
}

1;
