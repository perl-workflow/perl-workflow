package Workflow::Context;

# $Id$

use warnings;
use strict;
use base qw( Workflow::Base );

$Workflow::Context::VERSION = '1.05';

sub merge {
    my ( $self, $other ) = @_;
    my $other_params = $other->param();
    while ( my ( $k, $v ) = each %{$other_params} ) {
        $self->param( $k, $v );
    }
}

1;

__END__

=head1 NAME

Workflow::Context - Data blackboard for Workflows, Actions, Conditions and Validators

=head1 VERSION

This documentation describes version 1.05 of this package

=head1 SYNOPSIS

 # Create your own context and merge it with one that may already be
 # in a workflow
 
 my $context = Workflow::Context->new();
 $context->param( foo => 'bar' );
 $context->param( current_user => User->fetch( 'foo@bar.com' ) );
 $wf->context( $context );
 
 # In a Condition get the 'current_user' back out of the workflow's context
 
 sub evaluate {
     my ( $self, $wf ) = @_;
     my $current_user = $wf->context->param( 'current_user' );
     ...
 }
 
 # Set values directly into a workflow's context
 
 $wf->context->param( foo => 'bar' );
 $wf->context->param( news => My::News->fetch_where( 'date = ?', DateTime->now ) );

=head1 DESCRIPTION

Holds information to pass between your application and a Workflow,
including its Actions, Conditions and Validators.

=head1 OBJECT METHODS

=head3 merge( $other_context )

Merges the values from C<$other_context> into this object. If there
are duplicate keys in this object and C<$other_context>,
C<$other_context> wins.

=head1 SEE ALSO

L<Workflow>

=head1 COPYRIGHT

Copyright (c) 2003-2006 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt>, current maintainer.

Chris Winters E<lt>chris@cwinters.comE<gt>, original author.
