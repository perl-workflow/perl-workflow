package Workflow::Action::InputField;

# $Id$

use strict;
use base qw( Class::Accessor );

$Workflow::Action::InputField::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( name description type requirement );
__PACKAGE__->mk_accessors( @FIELDS );

sub new {
    my ( $class, $params ) = @_;
    my $self = bless( {}, $class );
    foreach my $field ( @FIELDS ) {
        next unless ( $params->{ $field } );
        $self->$field( $params->{ $field } );
    }
    my $requirement = ( $params->{is_required} eq 'yes' )
                        ? 'required' : 'optional';
    $self->requirement( $requirement );
    my $values = $params->{values} || $params->{possible_values};
    if ( $values ) {
        my @add_values = ( ref $values eq 'ARRAY' )
        $self->add_possible_values( @add_values );
    }
    $self->init( $params );
    return $self;
}

sub init { return }

sub is_required {
    my ( $self ) = @_;
    return ( $self->requirement eq 'required' ) ? 'yes' : 'no';
}

sub is_optional {
    my ( $self ) = @_;
    return ( $self->requirement eq 'optional' ) ? 'yes' : 'no';
}

sub get_possible_values {
    my ( $self ) = @_;
    return @{ $self->{_enumerated} };
}

sub add_possible_values {
    my ( $self, @values ) = @_;
    $self->{_enumerated} ||= [];
    push @{ $self->{_enumerated} }, @values;
    return @{ $self->{_enumerated} };
}

1;

__END__

=head1 NAME

Workflow::Action::InputField - Metadata about information required by an Action

=head1 SYNOPSIS

 # Declare the fields needed by your action in the configuration
 <action name="CreateUser">
    <field name="username"
           is_required="yes"
           source_class="App::Fied::ValidUsers"/>
    <field name="email"
           is_required="yes"/>
    <field name="office"
           source_list="Pittsburgh,Hong Kong,Moscow,Portland"/>
 </action>

=head1 DESCRIPTION

A workflow Action can declare one or more input fields required to do
its job. Think of it as a way for the external world (your
application) to discover what information an action needs from it. The
application can request these fields from the workflow by action name
and present them to the user in whatever form appropriate for the
application. The sample application shipped with this distribution
just cycles through them one at a time and presents a query to the
user for data entry.

For instance, in the above declaration there are three fields,
'username', 'email' and 'office'. So your application might do:

 my @action_fields = $wf->get_action_fields( 'CreateUser' );
 foreach my $field ( @action_fields ) {
     print "Field ", $field->name, "\n",
           $field->description, "\n",
           "Required? ", $field->is_required, "\n";
     my @enum = $field->get_possible_values;
     if ( scalar @enum ) {
         print "Possible values: ", join( ', ', @enum ), "\n";
     }
     print "Input? ";
     my $response = <STDIN>;
     chomp $response;
     $wf->context->param( $field->name => $response );
 }
 $wf->execute_action( 'CreateUser' );

=head1 METHODS

=head2 Public Methods

=head2 Properties

=head1 SEE ALSO

L<Workflow::Action>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
