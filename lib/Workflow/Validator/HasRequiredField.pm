package Workflow::Validator::HasRequiredField;

# $Id$

use strict;
use base qw( Workflow::Validator );
use Workflow::Exception qw( validation_error );

$Workflow::Validator::HasRequiredField::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub validate {
    my ( $self, $wf, @required_fields ) = @_;
    my $context = $wf->context;
    my @no_value = ();
    foreach my $field ( @required_fields ) {
        unless ( defined $context->param( $field ) ) {
            push @no_value, $field;
        }
    }
    if ( scalar @no_value ) {
        validation_error "The following fields require a value: ",
                         join( ', ', @no_value );
    }
}

1;

__END__

=head1 NAME

Workflow::Validator::HasRequiredField - Validator to ensure certain data are in the context

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

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
