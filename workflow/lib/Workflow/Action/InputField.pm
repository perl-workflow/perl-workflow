package Workflow::Action::InputField;

# $Id$

use strict;
use base qw( Class::Accessor );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( configuration_error );

$Workflow::Action::InputField::VERSION = '1.09';

my @FIELDS = qw( name label description type requirement source_class source_list );
__PACKAGE__->mk_accessors( @FIELDS );

my %INCLUDED = ();

sub new {
    my ( $class, $params ) = @_;
    my $log = get_logger();
    $log->debug( "Instantiating new field '$params->{name}'" );

    my $self = bless( {}, $class );

    # Set all our parameters
    foreach my $field ( @FIELDS ) {
        next unless ( $params->{ $field } );
        $self->$field( $params->{ $field } );
    }

    # ...ensure our name is defined
    unless ( $self->name ) {
        my $id_string = '[' .
                        join( '] [', map { "$_: $params->{$_}" }
                                         sort keys %{ $params } ) .
                        ']';
        configuration_error "Field found without name: $id_string";
    }

    my $name = $self->name;
    unless ( $self->label ) {
        $self->label( $name );
    }
    my $requirement = ( defined $params->{is_required} && $params->{is_required} eq 'yes' )
                        ? 'required' : 'optional';
    $self->requirement( $requirement );

    # ...ensure a class associated with the input source exists
    if ( my $source_class = $self->source_class ) {
        $log->debug( "Possible values for '$name' from '$source_class'" );
        unless ( $INCLUDED{ $source_class } ) {
            eval "require $source_class";
            if ( $@ ) {
                configuration_error "Failed to include source class ",
                                    "'$source_class' used in field '$name'";
            }
            $INCLUDED{ $source_class }++;
        }
        $params->{values} = [ $source_class->get_possible_values( $self ) ];
    }
    elsif ( $self->source_list ) {
        $log->debug( "Possible values for '$name' specified in config" );
        $params->{values} = [ split( /\s*,\s*/, $self->source_list ) ];
    }

    my $values = $params->{values} || $params->{possible_values};
    if ( $values ) {
        my @add_values = ( ref $values eq 'ARRAY' ) ? @{ $values } : ( $values );
        $log->debug( "Values to use as source for field '$name': ",
                     join( ', ', @add_values ) );
        $self->add_possible_values( @add_values );
    }

    # Assign the default field type, subclasses may override...
    $self->type( 'basic' );

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
    $self->{_enumerated} ||= [];
    return @{ $self->{_enumerated} };
}

sub add_possible_values {
    my ( $self, @values ) = @_;
    foreach my $value ( @values ) {
        my $this_value = ( ref $value eq 'HASH' )
                           ? $value
                           : { label => $value, value => $value };
        push @{ $self->{_enumerated} }, $this_value;
    }
    return @{ $self->{_enumerated} };
}

1;

__END__

=head1 NAME

Workflow::Action::InputField - Metadata about information required by an Action

=head1 SYNOPSIS

 # Declare the fields needed by your action in the configuration...
 
 <action name="CreateUser">
    <field name="username"
           is_required="yes"
           source_class="App::Field::ValidUsers" />
    <field name="email"
           is_required="yes" />
    <field name="office"
           source_list="Pittsburgh,Hong Kong,Moscow,Portland" />
 ...

=head1 DESCRIPTION

A workflow Action can declare one or more input fields required to do
its job. Think of it as a way for the external world (your
application) to discover what information an action needs from it. The
application can request these fields from the workflow by action name
and present them to the user in whatever form appropriate for the
application. The sample command-line application shipped with this
distribution just cycles through them one at a time and presents a
query to the user for data entry.

For instance, in the above declaration there are three fields,
'username', 'email' and 'office'. So your application might do:

 my @action_fields = $wf->get_action_fields( 'CreateUser' );
 foreach my $field ( @action_fields ) {
     print "Field ", $field->name, "\n",
           $field->description, "\n",
           "Required? ", $field->is_required, "\n";
     my @enum = $field->get_possible_values;
     if ( scalar @enum ) {
         print "Possible values: \n";
         foreach my $val ( @enum ) {
             print "  $val->{label} ($val->{value})\n";
         }
     }
     print "Input? ";
     my $response = <STDIN>;
     chomp $response;
     $wf->context->param( $field->name => $response );
 }
 $wf->execute_action( 'CreateUser' );

=head1 METHODS

=head2 Public Methods

=head3 new( \%params )

Typical constructor; will throw exception if 'name' is not defined or
if the property 'source_class' is defined but the class it specifies
is not available.

=head3 is_required()

Returns 'yes' if field is required, 'no' if optional.

=head3 is_optional()

Returns 'yes' if field is optional, 'no' if required.

=head3 get_possible_values()

Returns list of possible values for this field. Each possible value is
represented by a hashref with the keys 'label' and 'value' which makes
it easy to create dropdown lists in templates and the like.

=head3 add_possible_values( @values )

Adds possible values to be used for this field. Each item in
C<@values> may be a simple scalar or a hashref with the keys 'label'
and 'value'.

#=head3 init

=head2 Properties

B<name> (required)

Name of the field. This is what the action expects as the key in the
workflow context.

B<label> (optional)

Label of the field. If not set the value for C<name> is used.

B<description> (optional)

What does the field mean? This is not required for operation but it is
B<strongly> encouraged so your clients can create front ends to feed
you the information without much fuss.

B<type> (optional)

TODO: Datatype of field (still under construction...). By default it
is set to 'basic'.

B<requirement> ('required'|'optional')

If field is required, 'required', otherwise 'optional'.

B<source_class> (optional)

If set the field will call 'get_possible_values()' on the class when
the field is instantiated. This should return a list of either simple
scalars or a list of hashrefs with 'label' and 'value' keys.

B<source_list> (optional)

If set the field will use the specified comma-separated values as the
possible values for the field. The resulting list returned from
C<get_possible_values()> will have the same value for both the 'label'
and 'value' keys.

=head1 SEE ALSO

L<Workflow::Action>

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
