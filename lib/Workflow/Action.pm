package Workflow::Action;

# $Id$

# Note: we may implement a separate event mechanism so that actions
# can trigger other code (use 'Class::Observable'? read observations
# from database?)

use strict;
use base qw( Workflow::Base );
use Log::Log4perl     qw( get_logger );
use Workflow::Factory qw( FACTORY );

$Workflow::Action::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( name class description );
__PACKAGE__->mk_accessors( @FIELDS );

########################################
# PUBLIC

####################
# INPUT FIELDS

sub add_fields {
    my ( $self, @fields ) = @_;
    push @{ $self->{_fields} }, @fields;
}

sub required_fields {
    my ( $self ) = @_;
    return grep { $_->{type} eq 'required' } @{ $self->{_fields} };
}

sub optional_fields {
    my ( $self ) = @_;
    return grep { $_->{type} eq 'optional' } @{ $self->{_fields} };
}

sub fields {
    my ( $self ) = @_;
    return @{ $self->{_fields} };
}

####################
# VALIDATION

sub add_validators {
    my ( $self, @validator_info ) = @_;
    my @validators = ();
    foreach my $conf ( @validator_info ) {
        my $validator = FACTORY->get_validator( $conf->{name} );
        my @args = $self->normalize_array( $conf->{arg} );
        push @validators, { validator => $validator,
                            args      => \@args };
    }
    push @{ $self->{_validators} }, @validators;
}

sub get_validators {
    my ( $self ) = @_;
    return @{ $self->{_validators} };
}

sub validate {
    my ( $self, $wf ) = @_;
    my @validators = $self->_get_validators;
    return unless ( scalar @validators );

    my $context = $wf->context;
    foreach my $validator_info ( @validators ) {
        my $validator = $validator_info->{validator};
        my $args      = $validator_info->{args};
        my @runtime_args = ( $wf );
        foreach my $arg ( @{ $args } ) {
            if ( $arg =~ /^\$(.*)$/ ) {
                push @runtime_args, $context->param( $1 );
            }
            else {
                push @runtime_args, $arg;
            }
        }
        $validator->validate( @runtime_args );
    }
}

# Subclasses override...

sub execute  {
    my ( $self, $wf ) = @_;
    die "Class ", ref( $self ), " must implement 'execute()'\n";
}

########################################
# PRIVATE

sub init {
    my ( $self, $wf, $params ) = @_;

    # So we don't destroy the original...
    my %copy_params = %{ $params };

    $self->workflow( $wf );
    $self->class( $copy_params{class} );
    $self->name( $copy_params{name} );
    $self->description( $copy_params{description} );

    my @fields = $self->normalize_array( $copy_params{field} );
    foreach my $field_info ( @fields ) {
        $self->add_fields( Workflow::Action::InputField->new( $field_info ) );
    }

    my @validator_info = $self->normalize_array( $copy_params{validator} );
    $self->_set_validators( @validator_info );

    delete @copy_params{ qw( class name description field validator ) };

    # everything else is just a passthru param

    while ( my ( $key, $value ) = each %copy_params ) {
        $self->param( $key, $value );
    }
}

1;

__END__

=head1 NAME

Workflow::Action - Base class for Workflow actions

=head1 SYNOPSIS

 # Configure the Action...
 <action name="CreateUser"
         class="MyApp::Action::CreateUser">
   <field name="username" is_required="yes"/>
   <field name="email" is_required="yes"/>
   <validator name="IsUniqueUser">
       <arg name="$username"/>
   </validator>
   <validator name="IsValidEmail">
       <arg name="$email"/>
   </validator>
 </action>

 package MyApp::Action::CreateUser;
 
 use base qw( Workflow::Action );
 use Workflow::Exception qw( workflow_error );
 
 sub execute {
     my ( $self, $wf ) = @_;
     my $context = $wf->context;

     # Since 'username' and 'email' have already been validated we
     # don't need to check them for uniqueness, well-formedness, etc.

     my $user = eval {
         User->create({ username => $context->param( 'username' ),
                        email    => $context->param( 'email' ) })
     };

     # Wrap all errors returned...

     if ( $@ ) {
         workflow_error
             "Cannot create new user with name '", $context->param( 'username' ), "': $@";
     }

     # Set the created user in the context for the application and/or
     # other actions (observers) to use

     $context->param( user => $user );
 }

=head1 DESCRIPTION

This is the base class for all Workflow Actions. You do not have to
use it as such but it is strongly recommended.

=head1 OBJECT METHODS

=head2 Public Methods

B<add_field( @fields )>

Add one or more L<Workflow::Action::InputField>s to the action.

B<required_fields()>

Return a list of L<Workflow::Action::InputField> objects that are required.

B<optional_fields()>

Return a list of L<Workflow::Action::InputField> objects that are optional.

B<fields()>

Return a list of all L<Workflow::Action::InputField> objects
associated with this action.

B<add_validators( @validator_config )>

Given the 'validator' configuration declarations in the action
configuration, ask the L<Workflow::Factory> for the
L<Workflow::Validator> object associated with each name and store that
along with the arguments to be used, runtime and otherwise.

B<get_validators()>

Get a list of all the validator hashrefs, each with two keys:
'validator' and 'args'. The 'validator' key contains the appropriate
L<Workflow::Validator> object, while 'args' contains an arrayref of
arguments to pass to the validator, some of which may need to be
evaluated at runtime.

B<validate( $workflow )>

Run through all validators for this action. If any fail they will
throw a L<Workflow::Exception>, the validation subclass.

B<execute( $workflow )>

Subclasses must implement.

=head2 Private Methods

B<init( $workflow, \%params )>

=head1 SEE ALSO

L<Workflow>

L<Workflow::Factory>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
