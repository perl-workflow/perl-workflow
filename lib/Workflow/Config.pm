package Workflow::Config;

# $Id$

use warnings;
use strict;
use base qw( Class::Factory );
use Data::Dumper qw( Dumper );
use Log::Log4perl qw( get_logger );
use Workflow::Exception qw( configuration_error );

$Workflow::Config::VERSION = '1.13';

# Map the valid type to the top-level XML tag or data
# structure to look for.
my %VALID_TYPES = (
    action    => 'actions',
    condition => 'conditions',
    persister => 'persister',
    validator => 'validators',
    workflow  => 'workflow',
);

sub is_valid_config_type {
    my ( $class, $type ) = @_;
    return $VALID_TYPES{$type};
}

sub get_valid_config_types {
    my @keys = sort keys %VALID_TYPES;

    return @keys;
}

sub get_config_type_tag {
    my ( $class, $type ) = @_;
    return $VALID_TYPES{$type};
}

# Class method that allows you to pass in any type of items in
# @items. So you can do:
#
# Workflow::Config->parse_all_files( 'condition', 'my_condition.xml', 'your_condition.perl' );

sub parse_all_files {
    my ( $class, $type, @files ) = @_;

    return () unless ( scalar @files );

    my %parsers = ();
    my %parse_types = map { $_ => 1 } $class->get_registered_types;

    my @configurations = ();

    foreach my $file (@files) {
        next unless ($file);
        my ($file_type) = $file =~ /\.(\w+)$/;
        unless ( $parse_types{$file_type} ) {
            configuration_error
                "Cannot parse configuration file '$file' of workflow ",
                "type '$type'. The file has unknown configuration type ",
                "'$file_type'; known configuration types are: ", "'",
                join( ', ', keys %parse_types ), "'";
        }
        unless ( $parsers{$file_type} ) {
            $parsers{$file_type} = $class->new($file_type);
        }
        push @configurations, $parsers{$file_type}->parse( $type, $file );
    }
    return @configurations;
}

sub parse {
    my ( $self, $type, @items ) = @_;
    my $class = ref($self) || $self;
    configuration_error "Class $class must implement 'parse()'";
}

sub _check_config_type {
    my ( $class, $type ) = @_;
    unless ( $class->is_valid_config_type($type) ) {
        configuration_error "When parsing a configuration file the ",
            "configuration type (first argument) must be ", "one of: ",
            join ', ', $class->get_valid_config_types;
    }
}

sub _expand_refs {
    my (@items) = @_;
    my @all = ();

    if ( !scalar @items ) {
        return @all;
    }

    foreach my $item (@items) {
        next unless ($item);
        push @all, ( ref $item eq 'ARRAY' ) ? @{$item} : $item;
    }
    return @all;
}

__PACKAGE__->register_factory_type( perl => 'Workflow::Config::Perl' );
__PACKAGE__->register_factory_type( pl   => 'Workflow::Config::Perl' );
__PACKAGE__->register_factory_type( xml  => 'Workflow::Config::XML' );

1;

__END__

=head1 NAME

Workflow::Config - Parse configuration files for the workflow components

=head1 VERSION

This documentation describes version 1.12 of this package

=head1 SYNOPSIS

 # Reference multiple files
 
 my $parser = Workflow::Config->new( 'xml' );
 my @config = $parser->parse(
     'action', 'workflow_action.xml', 'other_actions.xml'
 );
 
 # Read in one of the file contents from somewhere else
 my $xml_contents = read_contents_from_db( 'other_actions.xml' );
 my @config = $parser->parse(
     'action', 'workflow_action.xml', \$xml_contents
 );
_
 # Reference multiple files of mixed types
 
 my @action_config = Workflow::Config->parse_all_files(
     'action', 'my_actions.xml', 'your_actions.perl'
 );

=head1 DESCRIPTION

Read in configurations for the various workflow components. Currently
the class understands XML (preferred) and serialized Perl data
structures as valid configuration file formats. (I tried to use INI
files but there was too much deeply nested information. Sorry.)

=head1 CLASS METHODS

=head3 parse_all_files( $workflow_config_type, @files )

Runs through each file in C<@files> and processes it according to the valid

=head1 SUBCLASSING

=head2 Creating Your Own Parser

If you want to store your configuration in a different format you can
create your own parser. All you need to do is:

=over 4

=item 1.

subclass L<Workflow::Config>

=item 2.

implement the required methods (listed below)

=item 3.

register your parser with L<Workflow::Config>.

=back

For instance, if you wanted to use YAML for configuration files you
would do something like:

 # just a convention, you can use any namespace you want
 package Workflow::Config::YAML;
 
 use strict;

 # Requirement 1: Subclass Workflow::Config
 use base qw( Workflow::Config );
 
 # Requirement 2: Implement required methods
 sub parse { ... }

The third requirement is registration, which just tells
L<Workflow::Config> which parser to use for a particular type. To do
this you have two options.

B<Registration option one>

Register yourself in your own class, adding the following call
anywhere the end:

 # Option 1: Register ourselves by name
 Workflow::Config->register_factory_type( yaml => 'Workflow::Config::YAML' );

Now you just need to include the configuration class in your workflow
invocation script:

 use strict;
 use Workflow::Factory qw( FACTORY );
 use Workflow::Config::YAML; # <-- brings in the registration

B<Registration option two>

You can also just explicitly add the registration from your workflow
invocation script:

 use strict;
 use Workflow::Factory qw( FACTORY );
 use Workflow::Config;
 
 # Option 2: explicitly register your configuration parser
 Workflow::Config->register_factory_type( yaml => 'Workflow::Config::YAML' );

Whichever one you choose you can now parse (in this example) YAML
files alongside the built-in parsers for XML and Perl files:

 FACTORY->add_config_from_file(
     workflow  => 'workflow.yaml',
     action    => [ 'my_actions.yaml', 'other_actions.xml' ],
     validator => 'validators.yaml',
     condition => [ 'my_conditions.yaml', 'other_conditions.xml' ]
     persister => 'persister.perl',
 );

=head2 Inherited Methods

=head3 new( $parser_type )

Instantiates an object of the correct type -- see L<Class::Factory>
for how this is implemented:

 # Parser of type 'Workflow::Config::XML'
 my $xml_parser  = Workflow::Config->new( 'xml' );
 
 # Parser of type 'Workflow::Config::Perl
 my $perl_parser = Workflow::Config->new( 'perl' );

=head3 is_valid_config_type( $config_type )

Returns true if C<$config_type> is a valid configuration type, false
if not. Valid configuration types are: 'action', 'condition',
'validator', 'workflow'.

=head3 get_valid_config_types()

Returns list of strings representing the valid configuration types.

=head3 get_config_type_tag( $class, $type )

Returns string representing a valid configuration type, looking up the type
parameter in a lookuptable defined in Workflow::Config class.

=head2 Required Object Methods

=head3 parse( $workflow_config_type, @items )

Parse each item in C<@items> to a hash reference based on the
configuration type C<$config_type> which must pass the
C<is_valid_config_type()> test. An 'item' is either a filename or a
scalar reference with the contents of a file. (You can mix and match
as seen in the L<SYNOPSIS>.)

Should throw an exception if:

=over 4

=item *

You pass an invalid workflow configuration type. Valid workflow
configuration types are registered in L<Workflow::Config> and are
available from C<get_valid_config_types()>; you can check whether a
particular type is valid with C<is_valid_config_type()>. (See above
for descriptions.)

=item *

You pass in a file that cannot be read or parsed because of
permissions, malformed XML, incorrect Perl data structure, etc. It
does B<not> do a validation check (e.g., to ensure that every 'action'
within a workflow state has a 'resulting_state' key).

=back

Returns: one hash reference for each member of C<@items>

=head1 CONFIGURATION INFORMATION

This gives you an idea of the configuration information in the various
workflow pieces:

=head2 workflow

   workflow
      type          $
      description   $
      persister     $
      initial_state $
      observer    \@
          sub           $
          class         $
      state       \@
          name          $
          description   $
          action        \@
              name            $
              resulting_state $
              condition       \@
                  name              $

=over 4

=item *

the 'type' and 'description' keys are at the top level

=item *

the 'extra_data' key holds an array of zero or more hashrefs with
'table', 'field', 'class' and 'context' keys


=item *

'initial_state' key holds a string declaring the name of the initial state.
by default, this value is 'INIITAL'.

=item *

'state' key holds array of one or more 'state' declarations; one of
them must be 'INITIAL' (or the value of initial_state, if it's defined)

=item *

each 'state' declaration holds 'description' and 'name' keys and
multiple 'action' declarations

=item *

each 'action' declaration holds 'name' and 'resulting_state' keys and
may hold a 'condition' key with one or more named conditions

=back

=head2 condition

 conditions:
 
     condition \@
        name  $
        class $
        param \@
            name  $
            value $

=over 4

=item *

array of one or more hashrefs with 'name' and 'class' keys

=back

=head2 validator

 validators:
 
     validator \@
        name  $
        class $
        param \@
            name  $
            value $

=over 4

=item *

array of one or more hashrefs with 'name' and 'class' keys, plus
possibly one or more 'param' hashrefs each with 'name' and 'value'
keys

=back

=head2 action

 actions:
 
    action \@
       name  $
       field \@
          name         $
          is_required  yes|no
          type         $
          source_list  \@ of $
          source_class $
          param        \@
              name  $
              value $
       validator \@
           name $
           arg  \@
               value $

=over 4

=item *

array of one or more action hashrefs with 'name', 'class' and
'description' keys

=item *

each 'action' may have zero or more values used to fill it; each value
has a 'name', 'description' and 'necessity' ('required' or 'optional')

=item *

each 'action' may have any number of 'param' hashrefs, each with
'name' and 'value'

=item *

each 'action' may have any number of 'validator' hashrefs, each with a
'name' key and array of 'arg' declarations

=back

=head2 persister

 persister:
 
   extra_table   $
   extra_field   $
   extra_class   $
   extra_context $

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
