package App::Action::TicketCreate;

# $Id$

use strict;
use base qw( Workflow::Action );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( persist_error );
use Workflow::Factory   qw( FACTORY );

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
        status      => $wf->state,
        subject     => $self->param( 'subject' ),
        description => $self->param( 'description' ),
        creator     => $creator,
        due_date    => $self->param( 'due_date' ),
        last_update => $self->param( 'last_update' ),
    });
    $ticket->create;
    $context->param( ticket => $ticket );
    $log->info( "Ticket created correctly with ID ", $ticket->id );
    my $sql = q{
      INSERT INTO workflow_ticket ( workflow_id, ticket_id )
      VALUES ( ?, ? )
    };
    $log->debug( "Will run SQL\n$sql" );
    $log->debug( "Will use parameters: ", join( ', ', $wf->id, $ticket->id ) );

    my $dbh = FACTORY->get_persister( 'TestPersister' )->handle;
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $sql );
        $sth->execute( $wf->id, $ticket->id );
    };
    if ( $@ ) {
        persist_error "Failed to save additional ticket info: $@";
    }
    $log->info( "Link table record inserted correctly" );
    $wf->add_history(
        Workflow::History->new({
            action      => 'Create ticket',
            description => 'New ticket created',
            user        => $creator,
            state       => $wf->state,
        })
    );
}

1;
