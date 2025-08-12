package Workflow::Action::Null;

use warnings;
use strict;
use v5.14.0;
use parent qw( Workflow::Action );

$Workflow::Action::Null::VERSION = '2.06';

sub execute {
    my ($self) = @_;
    return;
}

1;

__END__

=pod

=head1 NAME

Workflow::Action::Null - Workflow action for the terminally lazy

=head1 VERSION

This documentation describes version 2.06 of this package

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

Copyright (c) 2003-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
