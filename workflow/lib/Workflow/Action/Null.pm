package Workflow::Action::Null;

# $Id$

use strict;
use base qw( Workflow::Action );

$Workflow::Action::Null::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub execute {
    my ( $self ) = @_;
    return undef;
}

1;

__END__

=head1 NAME

Workflow::Action::Null - 

=head1 SYNOPSIS

 # in workflow.xml...
 <state name="some state">
   <action name="null" />
   ...
 
 # in workflow_action.xml...
 <action name="null" class="Workflow::Action::Null" />

=head1 DESCRIPTION

Workflow action that doesn't do anything. Can be useful if you just
want to move a workflow from one state to another without actually
doing anything.

=head1 OBJECT METHODS

B<execute()>

Implemented from L<Workflow::Action>. Always returns C<undef>.

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>


