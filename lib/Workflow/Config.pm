package Workflow::Config;

# $Id$

use strict;
use Data::Dumper        qw( Dumper );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( configuration_error );

$Workflow::Config::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

# Make for shorter calls...
sub new { return bless( {}, $_[0] ) }

my %VALID_TYPES = map { $_ => 1 } qw( action condition persister validator workflow );

sub is_valid_config_type {
    my ( $class, $type ) = @_;
    return $VALID_TYPES{ $type };
}

sub get_valid_config_types {
    return sort keys %VALID_TYPES;
}

sub parse {
    my ( $class, $type, @items ) = @_;
    my $log = get_logger();
    unless ( $class->is_valid_config_type( $type ) ) {
        configuration_error "When parsing a configuration file the ",
                            "configuration type (first argument) must be ",
                            "one of: ", join( ', ', $class->get_valid_config_types );
    }
    my @config_items = _expand_refs( @items );
    return () unless ( scalar @config_items );
    my @config = ();
    foreach my $item ( @config_items ) {
        my ( $file_type, $file_name );
        my $method;

        # $item is a scalar ref with config contents...

        if ( ref $item ) {
            $file_type = 'perl';
            $file_type = 'xml' if ( $$item =~ m/^\s*</ && $$item =~ m/>\s*$/ );
            $method = '_translate_' . $file_type;
            $file_name = '[scalar ref]';
        }

        # $item is a filename...
        else {
            ( $file_type ) = $item =~ /\.(\w+)$/;
            $method = '_translate_' . $file_type . '_file';
            $file_name = $item;
        }
        $log->is_info &&
            $log->info( "'$type' config file '$file_name' is type '$file_type'" );

        my ( $this_config );
        if ( $class->can( $method ) ) {
            $this_config = $class->$method( $type, $item );
        }
        else {
            configuration_error "Do not know how to parse configuration ",
                                "type '$type' from file '$item' of ",
                                "type '$file_type'";
        }
        $log->is_info &&
            $log->info( "Parsed file '$file_name' ok" );
        if ( ref $this_config->{ $type } eq 'ARRAY' ) {
            $log->debug( "Adding multiple configurations for '$type'" );
            push @config, @{ $this_config->{ $type } };
        }
        else {
            push @config, $this_config;
        }
    }
    return @config;
}

sub _expand_refs {
    my ( @items ) = @_;
    my @all = ();
    foreach my $item ( @items ) {
        next unless ( $item );
        push @all, ( ref $item eq 'ARRAY' ) ? @{ $item } : $item;
    }
    return @all;
}


sub _translate_perl_file {
    my ( $class, $type, $file ) = @_;
    my $log = get_logger();

    local $/ = undef;
    open( CONF, '<', $file )
        || configuration_error "Cannot read file '$file': $!";
    my $config = <CONF>;
    close( CONF );
    my $data = $class->_translate_perl( $type, $config, $file );
    $log->is_debug &&
        $log->debug( "Translated '$type' '$file' into: ", Dumper( $data ) );
    return $data;
}

sub _translate_perl {
    my ( $class, $type, $config, $file ) = @_;
    my $log = get_logger();

    no strict 'vars';
    my $data = eval $config;
    if ( $@ ) {
        configuration_error "Cannot evaluate perl data structure ",
                            "in '$file': $@";
    }
    return $data;
}


my %XML_OPTIONS = (
    action => {
        ForceArray => [ 'action', 'field', 'source_list', 'param', 'validator', 'arg' ],
        KeyAttr    => [],
    },
    condition => {
        ForceArray => [ 'condition', 'param' ],
        KeyAttr    => [],
    },
    persister => {
        ForceArray => [ 'persister' ],
        KeyAttr    => [],
    },
    validator => {
        ForceArray => [ 'validator', 'param' ],
        KeyAttr    => [],
    },
    workflow => {
        ForceArray => [ 'extra_data', 'state', 'action', 'condition' ],
        KeyAttr    => [],
    },
);

my $XML_REQUIRED = 0;

sub _translate_xml_file {
    my ( $class, $type, $file ) = @_;
    my $log = get_logger();
    my $config = $class->_translate_xml( $type, $file, $file );
    $log->is_debug &&
        $log->debug( "Translated '$type' '$file' into: ", Dumper( $config ) );
    return $config;
}

# $config can either be a filename or scalar ref with file contents

sub _translate_xml {
    my( $class, $type, $config, $file ) = @_;
    my $log = get_logger();
    unless ( $XML_REQUIRED ) {
        require XML::Simple;
        XML::Simple->import( ':strict' );
        $XML_REQUIRED++;
    };

    my $options = $XML_OPTIONS{ $type } || {};
    my $data = XMLin( $config, %{ $options } );
    return $data;
}

1;

__END__

=head1 NAME

Workflow::Config - Parse configuration files for the workflow components

=head1 SYNOPSIS

 # Reference multiple files
 
 my @config = Workflow::Config->parse(
                    'action', 'workflow_action.xml', 'other_actions.xml' );
 
 # Read in one of the file contents from somewhere else
 my $xml_contents = read_contents_from_db( 'other_actions.xml' );
 my @config = Workflow::Config->parse(
                    'action', 'workflow_action.xml', \$xml_contents );

=head1 DESCRIPTION

Read in configurations for the various workflow components. Currently
the class understands XML (preferred) and serialized Perl data
structures as valid configuration file formats. (I tried to use INI
files but there was too much deeply nested information. Sorry.)

=head1 CLASS METHODS

B<parse( $config_type, @items )>

Parse each item in C<@items> to a hash reference based on the
configuration type C<$config_type> which must pass the
C<is_valid_config_type()> test. An 'item' is either a filename or a
scalar reference with the contents of a file. (You can mix and match as seen in the L<SYNOPSIS>.)

If you are using filenames each must end with 'perl' or 'xml' and will
be parsed appropriately. If you are using references with the content
we do a best-guess to figure out what type of content you are passing
us.

Throws an exception if you pass one or more invalid configuration
types, if I do not know what configuration parser to use (file ends in
something other than 'xml' or 'perl'), or if any file cannot be read
or parsed because of permissions, malformed XML, incorrect Perl data
structure, etc. It does B<not> do a validation check (e.g., to ensure
that every 'action' within a workflow state has a 'resulting_state'
key).

Returns: list of hash references for each file in C<@files>

B<is_valid_config_type( $config_type )>

Returns true if C<$config_type> is a valid configuration type, false
if not. Valid configuration types are: 'action', 'condition',
'validator', 'workflow'.

B<get_valid_config_types()>

Returns list of strings representing the valid configuration types.

=head1 CONFIGURATION INFORMATION

=head2 workflow

   workflow
      type        $
      description $
      persister   $
      state       \@
          name          $
          description   $
          action        \@
              name            $
              resulting_state $
              condition       \@
                  name $

=over 4

=item *

the 'type' and 'description' keys are at the top level

=item *

the 'extra_data' key holds an array of zero or more hashrefs with
'table', 'field', 'class' and 'context' keys

=item *

'state' key holds array of one or more 'state' declarations; one of
them must be 'INITIAL'

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
