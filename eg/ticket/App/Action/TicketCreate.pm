package App::Action::TicketCreate;

# $Id$

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );

$App::Action::TicketCreate::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub execute {
    my ( $self, $wf ) = @_;
    my $context = $wf->context;
    my @fields = qw( subject description due_date creator );
    foreach my $field ( @fields ) {
        $self->param( $field, $context->param( $field ) );
    }
    $self->param( 'creator',  );

    my $log = get_logger();
    $log->debug( "Action '", $self->name, "' with class '", ref( $self ), "' executing..." );
    my $creator = $self->param( 'creator' ) || $context->param( 'current_user' );
    my $ticket = App::Ticket->new({
        subject     => $self->param( 'subject' ),
        description => $self->param( 'description' ),
        creator     => $creator,
        due_date    => $self->param( 'due_date' ),
        last_update => $self->param( 'last_update' ),
    });
    $ticket->status( $wf->state );
    $ticket->save;
    $context->param( ticket => $ticket );
    $log->info( "Ticket created correctly with ID ", $ticket->id );
#    my $sql = qq{
#      INSERT INTO workflow_ticket ( workflow_id, ticket_id )
#      VALUES ( $ticket->{workflow_id}, $ticket->{ticket_id} )
#    };
#    $ticket->global_datasource_handle->do( $sql );
#    $log->info( "Link table record inserted correctly" );
}

1;
