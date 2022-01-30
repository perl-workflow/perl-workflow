package Workflow::Condition::Autorun;

use warnings;
use strict;
use v5.14.0;

our $VERSION = '1.57';

use parent qw( Workflow::Condition );

sub evaluate {
    my ($self, $wf) = @_;
    return $wf->autorun;
}


1;

__END__

=pod

=head1 NAME

Workflow::Condition::Autorun - Condition evaluation in 'autorun' context

=head1 VERSION

This documentation describes version 1.57 of this package

=head1 DESCRIPTION

This condition can be used to include (or exclude, when negated) actions
from workflow execution; e.g. to make sure an action can only be triggered
outside of autorun state.

=head1 SYNOPSIS

In condition.xml:

    <condition name="is_autorun" class="Workflow::Condition::Autorun" />

In workflow.xml:

    <state name="CHECK_APPROVALS" autorun="yes">
        <action name="null_1" resulting_state="APPROVED">
            <condition name="!is_autorun" />
        </action>
        <action name="notify-check" resulting_state="AWAITING_APPROVAL">
            <condition name="is_autorun" />
        </action>
    </state>

=cut

=head1 AUTHORS

See L<Workflow>

=head1 COPYRIGHT

Copyright (c) 2004-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
