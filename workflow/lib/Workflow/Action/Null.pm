package Workflow::Action::Null;

# $Id$

use warnings;
use strict;
use base qw( Workflow::Action );

$Workflow::Action::Null::VERSION = '1.03';

sub execute {
    my ($self) = @_;
    return undef;
}

1;

__END__

=head1 NAME

Workflow::Action::Null - Workflow action for the terminally lazy

=head1 VERSION

This documentation describes version 1.03 of this package

=head1 SYNOPSIS

 # in workflow.xml...
 <state name="some state">
   <action name="null" />
   ...
 
 # in workflow_action.xml...
 <action name="null" class="Workflow::Action::Null" />

=head1 DESCRIPTION

Workflow action that does nothing. But unlike all those other lazy
modules out there, it does nothing with a purpose! For instance, you
might want some poor slobs to have some action verified but the elite
masters can skip the work entirely. So you can do:

  <state name="checking" autorun="yes">
     <action name="verify" resulting_state="verified">
         <condition name="isPoorSlob" />
     </action>
     <action name="null" resulting_state="verified">
         <condition name="isEliteMaster" />
     </action>
  </state>

=head1 OBJECT METHODS

=head3 execute()

Implemented from L<Workflow::Action>. Proudly does nothing and proves
it by returning C<undef>.

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>


