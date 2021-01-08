package Workflow::Condition;

use warnings;
use strict;
use base qw( Workflow::Base );
use Carp qw(croak);

$Workflow::Condition::CACHE_RESULTS = 1;
$Workflow::Condition::VERSION = '1.48';

my @FIELDS = qw( name class );
__PACKAGE__->mk_accessors(@FIELDS);

sub init {
    my ( $self, $params ) = @_;
    $self->name( $params->{name} );
    $self->class( $params->{class} );
    $self->_init($params);
}

sub _init {return}

sub evaluate {
    my ($self) = @_;
    croak "Class ", ref($self), " must implement 'evaluate()'!\n";
}

1;

__END__

=head1 NAME

Workflow::Condition - Evaluate a condition depending on the workflow state and environment

=head1 VERSION

This documentation describes version 1.07 of this package

=head1 SYNOPSIS

 # First declare the condition in a 'workflow_condition.xml'...

 <conditions>
   <condition
      name="IsAdminUser"
      class="MyApp::Condition::IsAdminUser">
         <param name="admin_group_id" value="5" />
         <param name="admin_group_id" value="6" />
   </condition>
 ...

 # Reference the condition in an action of the state/workflow definition...
 <workflow>
   <state>
     ...
     <action name="SomeAdminAction">
       ...
       <condition name="IsAdminUser" />
     </action>
     <action name="AnotherAdminAction">
      ...
      <condition name="IsAdminUser" />
     </action>
     <action name="AUserAction">
      ...
      <condition name="!IsAdminUser" />
     </action>
   </state>
   ...
 </workflow>

 # Then implement the condition

 package MyApp::Condition::IsAdminUser;

 use strict;
 use base qw( Workflow::Condition );
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
     unless ( $current_user ) {
         condition_error "No user defined, cannot check groups";
     }
     foreach my $group ( @{ $current_user->get_groups } ) {
         return if ( $admin_ids->{ $group->id } );
     }
     condition_error "Not member of any Admin groups";
 }

=head1 DESCRIPTION

Conditions are used by the workflow to see whether actions are
available in a particular context. So if user A asks the workflow for
the available actions she might get a different answer than user B
since they determine separate contexts.

B<NOTE>: The condition is enforced by Workflow::State. This means that
the condition name must be visible inside of the state definition. If
you specify the reference to the condition only inside of the full
action specification in a seperate file then nothing will happen. The
reference to the condition must be defined inside of the state/workflow
specification.

=head1 CONFIGURATION

While some conditions apply to all workflows, you may have a case where
a condition has different implementations for different workflow types.
For example, IsAdminUser may look in two different places for two
different workflow types, but you want to use the same condition name
for both.

You can accomplish this by adding a type in the condition configuration.

 <conditions>
 <type>Ticket</type>
   <condition
      name="IsAdminUser"
      class="MyApp::Condition::IsAdminUser">
         <param name="admin_group_id" value="5" />
         <param name="admin_group_id" value="6" />
   </condition>
 ...

The type must match a loaded workflow type, or the condition won't work.
When the workflow looks for a condition, it will look for a typed condition
first. If it doesn't find one, it will look for non-typed conditions.

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

=head3 init( \%params )

This is optional, but called when the condition is first
initialized. It may contain information you will want to initialize
your condition with in C<\%params>, which are all the declared
parameters in the condition declartion except for 'class' and 'name'.

You may also do any initialization here -- you can fetch data from the
database and store it in the class or object, whatever you need.

If you do not have sufficient information in C<\%params> you should
throw an exception (preferably 'configuration_error' imported from
L<Workflow::Exception>).

=head3 evaluate( $workflow )

Determine whether your condition fails by throwing an exception. You
can get the application context information necessary to process your
condition from the C<$workflow> object.

=head3 _init

This is a I<dummy>, please refer to L</init>

=head2 Caching and inverting the result

If in one state, you ask for the same condition again, Workflow uses
the cached result, so that within one list of available actions, you
will get a consistent view. Note that if we would not use caching,
this might not necessary be the case, as something external might
change between the two evaluate() calls.

Caching is also used with an inverted condition, which you can specify
in the definition using C<<condition name="!some_condition">>.
This condition returns exactly the opposite of the original one, i.e.
if the original condition fails, this one does not and the other way
round. As caching is used, you can model "yes/no" decisions using this
feature - if you have both C<<condition name="some_condition">> and
C<<condition name="!some_condition">> in your workflow state definition,
exactly one of them will succeed and one will fail - which is particularly
useful if you use "autorun" a lot.

Caching can be disabled by changing C<$Workflow::Condition::CACHE_RESULTS>
to zero (0):

    $Workflow::Condition::CACHE_RESULTS = 0;

All versions before 1.49 used a mechanism that effectively caused global
state. To address the problems that resulted (see GitHub issues #9 and #7),
1.49 switched to a new mechanism with a cache per workflow instance.

=head1 COPYRIGHT

Copyright (c) 2003-2007 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt> is the current maintainer.

Chris Winters E<lt>chris@cwinters.comE<gt>, original author.

=cut
