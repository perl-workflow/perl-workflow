package Workflow::Validator;

use warnings;
use strict;
use v5.14.0;
use parent qw( Workflow::Base );

$Workflow::Validator::VERSION = '2.05';

my @FIELDS = qw( description name );
__PACKAGE__->mk_accessors(@FIELDS);

sub init {
    my ( $self, $params ) = @_;

    $self->description( $params->{description} );
    if ( $params->{name} ) {
        $self->name( $params->{name} );
    } else {
        $self->name((ref $self ? ref $self : $self) . " (init in Action)");
    }
}

1;

__END__

=pod

=head1 NAME

Workflow::Validator - Interface definition for data validation

=head1 VERSION

This documentation describes version 2.05 of this package

=head1 SYNOPSIS

 # First declare the validator...
 <validator name="DateValidator"
            class="MyApp::Validator::Date">
   <param name="date_format" value="%Y-%m-%d %h:%m"/>
 </validator>

 # Then associate the validator with runtime data from the context...
 <action name="MyAction">
    <validator name="DateValidator">
       <arg>$due_date</arg>
    </validator>
 </action>

 # TODO: You can also inintialize and instantiate in one step if you
 # don't need to centralize or reuse (does this work?)

 <action name="MyAction">
    <validator class="MyApp::Validator::Date">
       <param name="date_format" value="%Y-%m-%d %h:%m"/>
       <arg>$due_date</arg>
    </validator>
 </action>

 # Then implement the logic using your favorite object system; e.g. Moo

 package MyApp::Validator::Date;

 use strict;
 use DateTime::Format::Strptime;
 use Workflow::Exception qw( validation_error );

 use Moo;

 has description => (is => 'ro', required => 0);

 has name => (is => 'ro', required => 1);

 has date_format => (is => 'ro', required => 1);

 has formatter => (is => 'ro', builder => '_build_formatter');

 around BUILDARGS => sub {
     my ( $orig, $class, @args ) = @_;

     # Note: When you derive from Workflow::Base, this mapping is done for you
     @args = (%{$args[0]},
              map {
                  $_ => $args[0]->{param}->{$_}
              } keys %{$args[0]->{param} // {}}
             )
        if scalar(@args) == 1 and ref $args[0] eq 'HASH';
     return $class->$orig(@args);
 }

 sub _build_formatter {
     my ( $self ) = @_;

     return DateTime::Format::Strptime->new(
               pattern => $self->date_format,
               on_error => 'undef'
     );
 }

 sub validate {
     my ( $self, $wf, $date_string ) = @_;
     my $fmt = $self->formatter;
     my $date_object = $fmt->parse_datetime( $date_string );
     unless ( $date_object ) {
         validation_error
             "Date '$date_string' does not match pattern '", $fmt->pattern, "' ",
             "due to error '", $fmt->errstr, "'";
     }
 }


 # Or, implement the same, based on Workflow::Base

 package MyApp::Validator::Date::Alternative;

 use warnings;
 use strict;
 use base qw( Workflow::Base );

 use DateTime::Format::Strptime;
 use Workflow::Exception qw( configuration_error validation_error );

 my @FIELDS = qw( name date_format formatter );
 __PACKAGE__->mk_accessors(@FIELDS);

 sub init {
     my ( $self, $params ) = @_;

     $self->name( $params->{name} );
     $self->date_format( $params->{date_format});
     $self->formatter( DateTime::Format::Strptime->new(
               pattern => $self->date_format,
               on_error => 'undef'));
 }


 sub validate {
     my ( $self, $wf, $date_string ) = @_;
     my $fmt = $self->formatter;
     my $date_object = $fmt->parse_datetime( $date_string );
     unless ( $date_object ) {
         validation_error
             "Date '$date_string' does not match pattern '", $fmt->pattern, "' ",
             "due to error '", $fmt->errstr, "'";
     }
 }

 1;



=head1 DESCRIPTION

Validators specified by 'validator_name' are looked up in the
L<Workflow::Factory> which reads a separate configuration and
generates validators. (Generally all validators should be declared,
but it is not required.)

Validators are objects with a single public method, 'validate()' that
take as arguments a workflow object and a list of parameters. The
parameters are filled in by the workflow engine in the order of
declaration in the Action.

The idea behind a validator is that it validates data but does not
care where it comes from.

=head1 SUBCLASSING

The validator is an interface definition, meaning that the validator
does not want or need to be subclassed. Any class can act as a
validator, as long as it adheres to the interface definition below.


=head1 INTERFACE

=head2 validate( $workflow, $data )

Throws a L<Workflow::ValidationError> when C<$workflow> doesn't comply
with the requirements of the validator. Returns successfully when it
does. In order to assess the state of the workflow, the validator can
directly use the workflow context as well as the mapped data.

When an action definition maps data into the validator, the validator may
or may not choose to use it to determine the validity of the workflow state.

Please note that the workflow engine currently has no means to detect the
number of data elements expected to be mapped into the validator; failure
to map the correct number in the configuration, should be detected at run
time (and can't be prevented with a configuration error).

=head1 COPYRIGHT

Copyright (c) 2003-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
