package Workflow::Validator;

# $Id$

use strict;
use base qw( Workflow::Base );

$Workflow::Validator::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( name class );
__PACKAGE__->mk_accessors( @FIELDS );

sub init {
    my ( $self, $params ) = @_;
    if ( $params->{name} ) {
        $self->name( $params->{name} );
    }
    else {
        $self->name( "$params->{class} (init in Action)" );
    }
    $self->class( $params->{class} );
    $self->_init( $params );
}

sub _init { return }

sub validate {
    my ( $self ) = @_;
    die "Class ", ref( $self ), " must implement 'validate()'!\n";
}

1;

__END__

=head1 NAME

Workflow::Validator - Ensure data are valid

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
 
 # Then implement the logic
 
 package MyApp::Validator::Date;
 
 use strict;
 use base qw( Workflow::Validator );
 use DateTime::Format::Strptime;
 use Workflow::Exception qw( configuration_error );
 
 __PACKAGE__->mk_accessors( 'formatter' );
 
 sub _init {
     my ( $self, $params ) = @_;
     unless ( $params->{date_format} ) {
         configuration_error
             "You must define a value for 'date_format' in ",
             "declaration of validator ", $self->name;
     }
     if ( ref $params->{date_format} ) {
         configuration_error
             "The value for 'date_format' must be a simple scalar in ",
             "declaration of validator ", $self->name;
     }
     my $formatter = DateTime::Format::Strptime->new(
                              pattern => $params->{date_format},
                              on_error => 'undef' );
     $self->formatter( $formatter );
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

=head1 DESCRIPTION

Validators specified by 'validator_name' are looked up in the
L<Workflow::Factory> which reads a separate configuration and
generates validators. (Generally all validators should be declared,
but it is not required.)

Validators are objects with a single public method, 'validate()' that
take as arguments a workflow object and a list of parameters. The
parameters are filled in by the workflow engine according to the
instantiation declaration in the Action.

The idea behind a validator is that it validates data but does not
care where it comes from.

=head1 SUBCLASSING

=head2 Strategy

=head2 Methods

B<_init( \%params )>

Called when the validator is first initialized. If you do not have
sufficient information in C<\%params> you should throw an exception.

B<validate( $workflow, $data )>

Determine whether your C<$data> is true or false. If necessary you can
get the application context information from the C<$workflow> object.

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
