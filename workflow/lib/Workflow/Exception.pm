package Workflow::Exception;

# $Id$

use warnings;
use strict;

# Declare some of our exceptions...

use Exception::Class (
    'Workflow::Exception::Condition' => {
        isa         => 'Workflow::Exception',
        description => 'Condition failed errors',
    },
    'Workflow::Exception::Configuration' => {
        isa         => 'Workflow::Exception',
        description => 'Configuration errors',
    },
    'Workflow::Exception::Persist' => {
        isa         => 'Workflow::Exception',
        description => 'Persistence errors',
    },
    'Workflow::Exception::Validation' => {
        isa         => 'Workflow::Exception',
        description => 'Validation errors',
        fields      => 'invalid_fields',
    },
);

use Log::Log4perl qw( get_logger );

my %TYPE_CLASSES = (
    condition_error     => 'Workflow::Exception::Condition',
    configuration_error => 'Workflow::Exception::Configuration',
    persist_error       => 'Workflow::Exception::Persist',
    validation_error    => 'Workflow::Exception::Validation',
    workflow_error      => 'Workflow::Exception',
);

$Workflow::Exception::VERSION   = '1.09';
@Workflow::Exception::ISA       = qw( Exporter Exception::Class::Base );
@Workflow::Exception::EXPORT_OK = keys %TYPE_CLASSES;

# Exported shortcuts

sub _mythrow {
    my ( $type, @items ) = @_;

    my ( $msg, %params ) = _massage(@items);
    my $log = get_logger();
    my ( $pkg, $line ) = (caller)[ 0, 2 ];
    my ( $prev_pkg, $prev_line ) = ( caller 1 )[ 0, 2 ];
    $log->error( "$type exception thrown from [$pkg: $line; before: ",
        "$prev_pkg: $prev_line]: $msg" );
    goto &Exception::Class::Base::throw(
        $TYPE_CLASSES{$type},
        message => $msg,
        %params
    );
}

# Use 'goto' here to maintain the stack trace

## no critic (Subroutines::RequireArgUnpacking)

sub condition_error {
    unshift @_, 'condition_error';
    goto &_mythrow;
}

sub configuration_error {
    unshift @_, 'configuration_error';
    goto &_mythrow;
}

sub persist_error {
    unshift @_, 'persist_error';
    goto &_mythrow;
}

sub validation_error {
    unshift @_, 'validation_error';
    goto &_mythrow;
}

sub workflow_error {
    unshift @_, 'workflow_error';
    goto &_mythrow;
}

# Override 'throw' so we can massage the message and parameters into
# the right format for E::C

sub throw {
    my ( $class, @items ) = @_;

    my ( $msg, %params ) = _massage(@items);
    goto &Exception::Class::Base::throw( $class, message => $msg, %params );
}

sub _massage {
    my @items = @_;

    my %params = ( ref $items[-1] eq 'HASH' ) ? %{ pop @items } : ();
    my $msg = join '', @items;
    return ( $msg, %params );
}

1;

__END__

=head1 NAME

Workflow::Exception - Base class for workflow exceptions

=head1 VERSION

This documentation describes version 1.08 of this package

=head1 SYNOPSIS

 # Standard usage
 use Workflow::Exception qw( workflow_error );
 
 my $user = $wf->context->param( 'current_user' );
 unless ( $user->check_password( $entered_password ) ) {
   workflow_error "User exists but password check failed";
 }
 
 # Pass a list of strings to form the message
 
 unless ( $user->check_password( $entered_password ) ) {
   workflow_error 'Bad login: ', $object->login_attempted;
 }
 
 # Using other exported shortcuts
 
 use Workflow::Exception qw( configuration_error );
 configuration_error "Field 'foo' must be a set to 'bar'";
 
 use Workflow::Exception qw( validation_error );
 validation_error "Validation for field 'foo' failed: $error";

=head1 DESCRIPTION

First, you should probably look at
L<Exception::Class|Exception::Class> for more usage examples, why we
use exceptions, what they are intended for, etc.

This is the base class for all workflow exceptions. It declares a
handful of exceptions and provides shortcuts to make raising an
exception easier and more readable.

=head1 METHODS

=head3 throw( @msg, [ \%params ])

This overrides B<throw()> from L<Exception::Class|Exception::Class> to
add a little syntactic sugar. Instead of:

 $exception_class->throw( message => 'This is my very long error message that I would like to pass',
                          param1  => 'Param1 value',
                          param2  => 'Param2 value' );

You can use:

 $exception_class->throw( 'This is my very long error message ',
                          'that I would like to pass',
                          { param1 => 'Param1 value',
                            param2 => 'Param2 value' } );

And everything will work the same. Combined with the L<SHORTCUTS> this
makes for very readable code:

 workflow_error "Something went horribly, terribly, dreadfully, "
                "frightfully wrong: $@",
                { foo => 'bar' };

=head3 condition_error

This method transforms the error to a condition error.

This exception is thrown via </mythrow> when a condition of a workflow is invalid.

=head3 configuration_error

This method transforms the error to a configuration error.

This exception is thrown via </mythrow> when configuration of a workflow is unsuccessful.

=head3 persist_error

This method transforms the error to a persistance error.

This exception is thrown via </mythrow> when the save of a workflow is unsuccessful.

=head3 validation_error

This method transforms the error to a validation error.

This exception is thrown via </mythrow> when input data or similar of a workflow is unsuccessful.

=head3 workflow_error

This method transforms the error to a workflow error.

This exception is thrown via </mythrow> when input data or similar of a workflow is unsuccessful.

=head1 SHORTCUTS

B<Workflow::Exception> - import using C<workflow_error>

B<Workflow::Exception::Condition> - import using C<condition_error>

B<Workflow::Exception::Configuration> - import using C<configuration_error>

B<Workflow::Exception::Persist> - import using C<persist_error>

B<Workflow::Exception::Validation> - import using C<validation_error>

=head1 SEE ALSO

L<Exception::Class|Exception::Class>

=head1 COPYRIGHT

Copyright (c) 2003-2010 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt> is the current maintainer.

Chris Winters E<lt>chris@cwinters.comE<gt>, original author.

=cut
