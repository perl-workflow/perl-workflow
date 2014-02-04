package Workflow::Validator::HasRequiredField;

# $Id$

use warnings;
use strict;
use base qw( Workflow::Validator );
use Workflow::Exception qw( validation_error );

$Workflow::Validator::HasRequiredField::VERSION = '1.05';

sub validate {
    my ( $self, $wf, @required_fields ) = @_;
    my $context  = $wf->context;
    my @no_value = ();
    foreach my $field (@required_fields) {
        unless ( defined $context->param($field) ) {
            push @no_value, $field;
        }
    }
    if ( scalar @no_value ) {
        validation_error "The following fields require a value: ", join ', ',
            @no_value, { invalid_fields => \@no_value };
    }
}

1;

__END__

=head1 NAME

Workflow::Validator::HasRequiredField - Validator to ensure certain data are in the context

=head1 VERSION

This documentation describes version 1.04 of this package

=head1 SYNOPSIS

 # Validator is created automatically when you mark a field as
 # 'is_required=yes' in the action, such as:
 
 <action name="CreateUser">
    <field name="username"
           is_required="yes"
           source_class="App::Fied::ValidUsers"/>
    ...

=head1 DESCRIPTION

This is a simple validator to ensure that each of the fields you have
marked with the 'is_required' property as 'yes' are indeed present
before the associated action is executed.

for instance, given the configuration:

 <action name="CreateUser">
    <field name="username"
           is_required="yes"/>
    <field name="email"
           is_required="yes"/>
    <field name="office">
 </action>

An action executed with such a context:

 my $wf = FACTORY->get_workflow( $id );
 $wf->context( username => 'foo' );
 $wf->context( office => 'Ottumwa' );
 $wf->execute_action( 'CreateUser' );

Would fail with a message:

 The following fields require a value: email

You normally do not need to configure this validator yourself. It gets
generated automatically when the Action configration is read
in. However, if you do need to create it yourself:

 <action name='Foo'>
    <validator name="HasRequiredField">
       <arg value="fieldOne"/>
       <arg value="field_two"/>
    </validator>
 <?action>

Note that we do not try to match the value in the context against a
set of known values or algorithm, just see if the value is defined --
using the Perl notion for defined rather than true/false, which means
'0' and the empty string will both be valid.

=head2 METHODS

=head3 validate

Validates whether a given set of required fields are defined.

Takes two parameters: a workflow object and an array of names of fields.

The provided fields are matched against the workflow in question and
L<Workflow::Exception>'s are thrown in case of missing fields.

=head1 COPYRIGHT

Copyright (c) 2003-2010 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt> is the current maintainer.

Chris Winters E<lt>chris@cwinters.comE<gt>, original author.

=cut
