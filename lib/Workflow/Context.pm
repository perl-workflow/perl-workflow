package Workflow::Context;

use warnings;
use strict;
use v5.14.0;
use parent qw( Workflow::Base );

$Workflow::Context::VERSION = '2.03';


sub init {
    my ( $self, %params) = @_;

    for my $key (keys %params) {
        $self->param( $key => $params{$key} );
    }
}

sub merge {
    my ( $self, $other ) = @_;
    my $other_params = $other->param();
    while ( my ( $k, $v ) = each %{$other_params} ) {
        $self->param( $k, $v );
    }
}

1;

__END__

=pod

=head1 NAME

Workflow::Context - Data blackboard for Workflows, Actions, Conditions and Validators

=head1 VERSION

This documentation describes version 2.03 of this package

=head1 SYNOPSIS

 # Create your own context and merge it with one that may already be
 # in a workflow

 my $context = Workflow::Context->new();
 $context->param( foo => 'bar' );
 $context->param( current_user => User->fetch( 'foo@bar.com' ) );
 my $wf = FACTORY()->create_workflow( 'w/f', $context );

 # The above is the same as:
 $context = Workflow::Context->new(
      foo   => 'bar',
      current_user => User->fetch( 'foo@bar.com' ),
 );
 $wf = FACTORY()->create_workflow( 'w/f', $context );


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

=head2 init( %params )

Adds C<%params> to the context at instantiation.

=head2 merge( $other_context )

Merges the values from C<$other_context> into this object. If there
are duplicate keys in this object and C<$other_context>,
C<$other_context> wins.

=head1 SEE ALSO

=over

=item * L<Workflow>

=back

=head1 COPYRIGHT

Copyright (c) 2003-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
