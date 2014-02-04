package Workflow::Validator::InEnumeratedType;

# $Id$

use warnings;
use strict;
use base qw( Workflow::Validator );
use Workflow::Exception qw( configuration_error validation_error );

$Workflow::Validator::InEnumeratedType::VERSION = '1.04';

sub _init {
    my ( $self, $params ) = @_;
    $self->{_enum}       = [];
    $self->{_enum_match} = {};
    unless ( $params->{value} ) {
        configuration_error "Validator 'InEnumeratedType' must be ",
            "initialized with the values you wish to ",
            "validate against using the parameter 'value'.";
    }
    my @values
        = ( ref $params->{value} eq 'ARRAY' )
        ? @{ $params->{value} }
        : ( $params->{value} );
    $self->add_enumerated_values(@values);
}

sub validator {
    my ( $self, $wf, $value ) = @_;
    unless ( $self->is_enumerated_value($value) ) {
        validation_error "Value '$value' must be one of: ", join ", ",
            $self->get_enumerated_values;
    }
}

sub add_enumerated_values {
    my ( $self, @values ) = @_;
    push @{ $self->{_enum} }, @values;
    $self->{_enum_match}{$_} = 1 for (@values);
}

sub get_enumerated_values {
    my ($self) = @_;
    return @{ $self->{_enum} };
}

sub is_enumerated_value {
    my ( $self, $value ) = @_;
    return $self->{_enum_match}{$value};
}

1;

__END__

=head1 NAME

Workflow::Validator::InEnumeratedType - Ensure a value is one of a declared set of values

=head1 VERSION

This documentation describes version 1.04 of this package

=head1 SYNOPSIS

 # Inline the enumeration...
 
 <action name="PlayGame">
   <validator name="InEnumeratedType">
      <value>Rock</value>
      <value>Scissors</value>
      <value>Paper</value>
      <arg value="$play"/>
   </validator>
 </action>
 
 # Or declare it in the validator to be more readable...
 <validator name="RSP"
            class="Validator::InEnumeratedType">
      <value>Rock</value>
      <value>Scissors</value>
      <value>Paper</value>
 </validator>
 
 # ...and use it in your action
 <action name="PlayGame">
    <validator name="RSP">
       <arg value="$play"/>
    </validator>
 </action>

=head1 DESCRIPTION

This validator ensures that a value matches one of a set of
values. You declare the values in the set (or enumerated type) in
either the main validator declaration or in the declaration inside the
action, then pass a single argument of the value in the context you
would like to check.

Declaring the members of the enumerated type in the validator
configuration makes for more readable (and brief) action
configurations, as well as making the types more reusable, but it is
really up to you.

=head1 SUBCLASSING

=head2 Strategy

Unlike some other validator classes this one is setup to be
subclassable. It is usable as-is, of course, but many times you will
find that you have need of more interesting types in your enumeration
than simple strings. So this class provides the hooks for you to
simply create your own.

For instance, in a trouble ticket system you may have the idea that
tickets can only be assigned to particular users. Maybe they are in a
'worker' role, maybe they are some administrators, whatever. By
creating a class to have these users as an enumerated type, combined
with declaring the required Action fields, you make for a pretty
powerful piece of reflection.

Onto the code. First we declare a field type of 'worker':

 <field type="worker"
        class="MyApp::Field::Worker"/>

Next a validator of this enumerated type:

 <validator name="IsWorker"
            class="MyApp::Validator::WorkerEnumeration"/>

We then associate this field type with a field in the action and the
validator to ensure the user selects a worker from the right pool:

 <action name="AssignTicket">
    <field name="assignee"
           type="worker"
           is_required="yes"/>
   ...
   <validator name="IsWorker">
       <arg value="$assignee"/>
   </validator>

Note that the name of the field and the name used in the validator are
the same. This allows external applications to query the action for
its fields, get 'assignee' as the name and get a list of User objects
(or something similar) as the types from which to choose a value, and
checks that same field to ensure a correct choice was submitted.

The implementation for the validator might look like:

 package MyApp::Validator::WorkerEnumeration;
 
 sub validate {
     my ( $self, $wf, $worker_id ) = @_;
     my $ticket = $context->param( 'ticket' );
     unless ( $ticket ) {
         my $ticket_id = $context->param( 'ticket_id' );
         $ticket = Ticket->fetch( $ticket_id );
     }
     my $workers = $ticket->fetch_available_workers();
     my @worker_id = map { $_->id } @{ $workers };
     $self->add_enumerated_values( @worker_id );
     $self->SUPER::validate( $wf, $worker_id );
 }

=head2 METHODS

=head3 _init( \%params )

This method initializes the class and the enumerated class.

It uses L</add_enumerated_values> to add the set of values for enumeration.

The primary parameter is value, which should be used to specify the
either a single value or a reference to array of values to be added.

=head3 validator

The validator method is the public API. It encapulates L</is_enumerated:value>
and works with L<Workflow>.

=head3 add_enumerated_values( @values )

This method ads an array of values to be regarded as enumerations for the
validator.

=head3 get_enumerated_values()

This method returns the defined enumerated values for the class as an array.

=head3 is_enumerated_value( $value )

This is most often the single method you will want to modify.

The method offers assertion of a given value, as to whether it is an enumerated
type as defined in the class.

=head1 EXCEPTIONS

=over

=item * Validator 'InEnumeratedType' must be initialized with the values you wish to validate against using the parameter 'value'.

This L<Workflow::Exception> is thrown from L</_init> if the 'value'
parameter is not set.

=item * Value '$value' must be one of: <@values>

This L<Workflow::Exception> is thrown from L</_validator> if the value
to be asserted is not mathing any of the enumerated values defined as
part of the set.

=back

=head1 COPYRIGHT

Copyright (c) 2003-2007 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Current maintainer Jonas B. Nielsen E<lt>jonasbn@cpan.orgE<gt>

Original author Chris Winters E<lt>chris@cwinters.comE<gt>


