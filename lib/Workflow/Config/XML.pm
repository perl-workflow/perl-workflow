package Workflow::Config::XML;

# $Id$

use warnings;
use strict;
use base qw( Workflow::Config );
use Log::Log4perl qw( get_logger );
use Workflow::Exception qw( configuration_error );
use Carp qw(croak);
use English qw( -no_match_vars );

$Workflow::Config::XML::VERSION = '1.05';

my ($log);

my %XML_OPTIONS = (
    action => {
        ForceArray =>
            [ 'action', 'field', 'source_list', 'param', 'validator', 'arg' ],
        KeyAttr => [],
    },
    condition => {
        ForceArray => [ 'condition', 'param' ],
        KeyAttr    => [],
    },
    persister => {
        ForceArray => ['persister'],
        KeyAttr    => [],
    },
    validator => {
        ForceArray => [ 'validator', 'param' ],
        KeyAttr    => [],
    },
    workflow => {
        ForceArray => [
            'extra_data', 'state',
            'action',     'resulting_state',
            'condition',  'observer'
        ],
        KeyAttr => [],
    },
);

my $XML_REQUIRED = 0;

sub parse {
    my ( $self, $type, @items ) = @_;
    $log ||= get_logger();

    $self->_check_config_type($type);
    my @config_items = Workflow::Config::_expand_refs(@items);
    return () unless ( scalar @config_items );

    my @config = ();
    foreach my $item (@config_items) {
        my $file_name = ( ref $item ) ? '[scalar ref]' : $item;
        $log->is_info
            && $log->info("Will parse '$type' XML config file '$file_name'");
        my $this_config;
        eval { $this_config = $self->_translate_xml( $type, $item ); };

        # If processing multiple config files, this makes it much easier
        # to find a problem.
        croak "Processing $file_name: $EVAL_ERROR" if $EVAL_ERROR;
        $log->is_info
            && $log->info("Parsed XML '$file_name' ok");

        # This sets the outer-most tag to use
        # when returning the parsed XML.
        my $outer_tag = $self->get_config_type_tag($type);
        if ( ref $this_config->{$outer_tag} eq 'ARRAY' ) {
            $log->is_debug
                && $log->debug("Adding multiple configurations for '$type'");
            push @config, @{ $this_config->{$outer_tag} };
        } else {
            $log->is_debug
                && $log->debug("Adding single configuration for '$type'");
            push @config, $this_config;
        }
    }
    return @config;
}

# $config can either be a filename or scalar ref with file contents

sub _translate_xml {
    my ( $self, $type, $config ) = @_;
    unless ($XML_REQUIRED) {
        eval { require XML::Simple };
        if ($EVAL_ERROR) {
            configuration_error "XML::Simple must be installed to parse ",
                "configuration files/data in XML format";
        } else {
            XML::Simple->import(':strict');
            $XML_REQUIRED++;
        }
    }
    my $options = $XML_OPTIONS{$type} || {};
    my $data = XMLin( $config, %{$options} );
    return $data;
}

1;

__END__

=head1 NAME

Workflow::Config::XML - Parse workflow configurations from XML content

=head1 VERSION

This documentation describes version 1.05 of this package

=head1 SYNOPSIS

 my $parser = Workflow::Config->new( 'xml' );
 my $conf = $parser->parse( 'condition',
                            'my_conditions.xml', 'your_conditions.xml' );

=head1 DESCRIPTION

Implementation of configuration parser for XML files/data; requires
L<XML::Simple> to be installed. See L<Workflow::Config> for C<parse()>
description.

=head2 METHODS

=head3 parse ( $type, @items )

This method parses the configuration provided it is in XML format.

Takes two parameters: a $type indication and an array of of items

Returns a list of config parameters as a array upon success.

=head1 SEE ALSO

L<XML::Simple>

L<Workflow::Config>

=head1 COPYRIGHT

Copyright (c) 2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
