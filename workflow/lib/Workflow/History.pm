package Workflow::History;

# $Id$

use strict;
use base qw( Class::Accessor );
use DateTime;

$Workflow::History::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( id workflow_id action description date user state );
__PACKAGE__->mk_accessors( @FIELDS );

sub new {
    my ( $class, $params ) = @_;
    my $self = bless( { _saved => 0 }, $class );
    for ( @FIELDS ) {
        $self->$_( $params->{ $_ } ) if ( $params->{ $_ } );
    }
    unless ( $self->date ) {
        $self->date( DateTime->now() );
    }
    return $self;
}

sub is_saved {
    my ( $self ) = @_;
    return $self->{_saved};
}

sub set_saved {
    my ( $self ) = @_;
    $self->{_saved} = 1;
}

sub clear_saved {
    my ( $self ) = @_;
    $self->{_saved} = 0;
}

1;

__END__

=head1 NAME

Workflow::History - Recorded work on a workflow action or workflow itself

=head1 SYNOPSIS

 # in your action
 sub execute {
     my ( $self, $wf ) = @_;
     my $current_user = $wf->context->param( 'current_user' );
     # ... do your work with $ticket
     $wf->add_history( action => 'create ticket',
                       user   => $current_user->full_name,
                       description => "Ticket $ticket->{subject} successfully created" );
 }

 # in your view (using TT2)
 [% FOREACH history = workflow.get_history %]
    On:     [% OI.format_date( history.date, '%Y-%m-%d %H:%M' ) %]<br>
    Action: [% history.action %] (ID: [% history.id %])<br>
    by:     [% history.user %]<br>
    [% history.description %]
 [% END %]

=head1 DESCRIPTION

Every workflow can record its history. More appropriately, every
action the workflow executes can deposit history entries in the
workflow to be saved later. Neither the action nor the workflow knows
about how the history is saved, just that the history is available.

=head1 METHODS

=head2 Public Methods

B<new( \%params )>

Create a new history object, filling it with properties from
C<\%params>.

B<is_saved()>

Returns true if this history object has been saved, false if not.

=head2 Properties

=over 4

=item *

B<id> - ID of history entry

=item *

B<workflow_id> - ID of workflow to which history is attached

=item *

B<action> - Brief description of action taken

=item *

B<description> - Lengthy description of action taken

=item *

B<date> - Date history noted, set to a L<DateTime> object.

=item *

B<user> - User name (ID, login, or full name, up to you) taking action
(may be blank)

=item *

B<state> - State of workflow as history was recorded.

=back

=head1 SEE ALSO

L<Workflow>

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
