package Workflow::History;

# $Id$

use warnings;
use strict;
use base qw( Class::Accessor );
use DateTime;

$Workflow::History::VERSION = '1.10';

my @FIELDS
    = qw( id workflow_id action description date user state time_zone );
__PACKAGE__->mk_accessors(@FIELDS);

sub new {
    my ( $class, $params ) = @_;
    my $self = bless { _saved => 0 }, $class;
    for (@FIELDS) {
        $self->$_( $params->{$_} ) if ( $params->{$_} );
    }

    my $time_zone
        = exists $params->{time_zone} ? $params->{time_zone} : 'floating';
    $self->time_zone($time_zone);

    unless ( $self->date ) {
        $self->date( DateTime->now( time_zone => $self->time_zone() ) );
    }
    return $self;
}

sub set_new_state {
    my ( $self, $new_state ) = @_;
    unless ( $self->state ) {
        $self->state($new_state);
    }
}

sub is_saved {
    my ($self) = @_;
    return $self->{_saved};
}

sub set_saved {
    my ($self) = @_;
    $self->{_saved} = 1;

    return 1;
}

sub clear_saved {
    my ($self) = @_;
    $self->{_saved} = 0;

    return 0;
}

1;

__END__

=head1 NAME

Workflow::History - Recorded work on a workflow action or workflow itself

=head1 VERSION

This documentation describes version 1.10 of this package

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

=head3 new( \%params )

Create a new history object, filling it with properties from
C<\%params>.

=head3 set_new_state( $new_state )

Assigns the new state C<$new_state> to the history if the state is not
already assigned. This is used when you generate a history request in
a L<Workflow::Action> since the workflow state will change once the
action has successfully completed. So in the action you create a
history object without the state:

  $wf->add_history(
      Workflow::History->new({
          action      => "Cocoa Puffs",
          description => "They're magically delicious",
          user        => "Count Chocula",
      })
  );

And then after the new state has been set but before the history
objects are stored the workflow sets the new state in all unsaved
history objects.

=head3 is_saved()

Returns true (1) if this history object has been saved, false (0) if not.

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

B<time_zone> - Time zone to pass to the L<DateTime> object.

=item *

B<user> - User name (ID, login, or full name, up to you) taking action
(may be blank)

=item *

B<state> - State of workflow as history was recorded.

=back

=head3 clear_saved

Sets saved state to false and returns 0

=head3 set_saved

Sets saved state to true and returns 1

=head1 SEE ALSO

L<Workflow>

=head1 COPYRIGHT

Copyright (c) 2003-2007 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt> is the current maintainer.

Chris Winters E<lt>chris@cwinters.comE<gt>

=cut
