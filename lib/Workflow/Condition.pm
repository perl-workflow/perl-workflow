package Workflow::Condition;

# $Id$

use strict;
use base qw( Workflow::Base );

$Workflow::Condition::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( name class );
__PACKAGE__->mk_accessors( @FIELDS );

sub init {
    my ( $self, $params ) = @_;
    $self->name( $params->{name} );
    $self->class( $params->{class} );
    $self->_init( $params );
}

sub _init { return }

sub evaluate {
    my ( $self ) = @_;
    die "Class ", ref( $self ), " must implement 'evaluate()'!\n";
}

1;

__END__

=head1 NAME

Workflow::Condition - Evaluate a condition depending on the workflow state and environment

=head1 SYNOPSIS

 # First declare the condition in a 'workflow_condition.ini'
 
 [IsAdminUser]
 class = MyApp::Condition::IsAdminUser
 admin_group_id = 5
 admin_group_id = 6
 
 [MyAction]
 condition = IsAdminUser
 
 # Then implement the condition
 
 package MyApp::Condition::IsAdminUser;
 
 use strict;
 use base qw( Condition );
 use Workflow::Exception qw( condition_error configuration_error );
 
 __PACKAGE__->mk_accessors( 'admin_group_id' );
 
 sub _init {
     my ( $self, $params ) = @_;
     unless ( $params->{admin_group_id} ) {
         configuration_error
             "You must define one or more values for 'admin_group_id' in ",
             "declaration of condition ", $self->name;
     }
     my @admin_ids = $self->_normalize_array( $params->{admin_group_id} );
     $self->admin_group_id( { map { $_ => 1 } @admin_ids } );
 }
 
 sub evaluate {
     my ( $self, $wf ) = @_;
     my $admin_ids = $self->admin_group_id;
     my $current_user = $wf->context->param( 'current_user' );
     foreach my $group ( @{ $current_user->get_groups } ) {
         return 1 if ( $admin_ids->{ $group->id } );
     }
     condition_error "Not member of any Admin groups";
 }

=head1 DESCRIPTION

Conditions are used by the workflow to see whether actions are
available in a particular context. So if user A asks the workflow for
the available actions she might get a different answer than user B
since they determine separate contexts.

=head1 SUBCLASSING

=head2 Strategy

The idea behind conditions is that they can be stateless. So when the
L<Workflow::Factory> object reads in the condition configuration it
creates the condition objects and initializes them with whatever
information is passed in.

Then when the condition is evaluated we just call C<evaluate()> on the
condition. Hopefully the operation can be done very quickly since the
condition may be called many, many times during a workflow lifecycle
-- they are typically used to show users what options they have given
the current state of the workflow for things like menu options. So
keep it short!

=head2 Methods

To create your own condition you should implement the following:

B<_init( \%params )>

This is optional, but called when the condition is first
initialized. It may contain information you will want to initialize
your condition with in C<\%params>, which are all the declared
parameters in the condition declartion except for 'class' and 'name'.

You may also do any initialization here -- you can fetch data from the
database and store it in the class or object, whatever you need.

If you do not have sufficient information in C<\%params> you should
throw an exception.

B<evaluate( $workflow )>

Determine whether your condition passes (return a true value) or false
(return 0 or undef). You can get the application context information
from the C<$workflow> object.

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
