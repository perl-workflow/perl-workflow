package Action::TicketCreate;

# $Id$

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );

$Action::TicketCreate::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub execute {
    my ( $self, $wf ) = @_;
    my $context = $wf->context;
    my @fields = qw( subject description due_date creator_id workflow_id );
    foreach my $field ( @fields ) {
        $self->param( $field, $context->param( $field ) );
    }
    $self->param( 'creator',  );

    my $log = get_logger();
    $log->debug( "Action '", $self->name, "' with class '", ref( $self ), "' executing..." );
    my $ticket = Ticket->new({ subject => $self->param( 'subject' ),
                               description => $self->param( 'description' ),
                               due_date    => $self->param( 'due_date' ),
                               workflow_id => $self->param( 'workflow_id' ) });
    my $creator_id = $self->param( 'creator_id' )
                     || $context->param( 'current_user' )->id;
    $ticket->{creator_id} = $creator_id;
    $ticket->save;
    $log->info( "Ticket created correctly with ID $ticket->{ticket_id}" );
    $context->param( ticket => $ticket );
    my $sql = qq{
      INSERT INTO workflow_ticket ( workflow_id, ticket_id ) 
      VALUES ( $ticket->{workflow_id}, $ticket->{ticket_id} )
    };
    $ticket->global_datasource_handle->do( $sql );
    $log->info( "Link table record inserted correctly" );
}

1;

__END__

=head1 NAME

Action::TicketCreate - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASS METHODS

=head1 OBJECT METHODS

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
