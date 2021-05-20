package TestApp::Action::TicketComment;

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );

$TestApp::Action::TicketComment::VERSION  = '1.02';

__PACKAGE__->mk_accessors(qw(index));

### Straight out of the Workflow::Action->new() documentation
sub new {
    my ($class, $wf, $params) = @_;
    my $self = $class->SUPER::new($wf, $params);
    $self->index($params->{index}) if defined $params->{index};

    return $self;
}

sub execute {
    my ( $self, $wf ) = @_;
    my $log = get_logger();

    $log->info( "Entering comment for workflow ", $wf->id );

    $wf->add_history(
        Workflow::History->new({
            action      => "Ticket comment",
            description => $wf->context->param( 'comment' ),
            user        => $wf->context->param( 'current_user' ),
        })
    );
}

1;
