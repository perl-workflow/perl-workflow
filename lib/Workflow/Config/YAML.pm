package Workflow::Config::YAML;

use warnings;
use strict;
use v5.14.0;
use parent qw( Workflow::Config );
use Log::Any qw( $log );
use Workflow::Exception qw( configuration_error );
use Carp qw(croak);
use Syntax::Keyword::Try;

$Workflow::Config::YAML::VERSION = '2.09';

my $YAML_REQUIRED = 0;

sub parse {
    my ( $self, $type, @items ) = @_;

    $self->_check_config_type($type);
    my @config_items = Workflow::Config::_expand_refs(@items);
    return () unless ( scalar @config_items );

    my @config = ();
    foreach my $item (@config_items) {
        my $file_name = ( ref $item ) ? '[scalar ref]' : $item;
        $log->info("Will parse '$type' YAML config file '$file_name'");
        my $this_config = do {
            try {
                $self->_translate_yaml( $type, $item );
            }
            catch ($error) {
                croak $log->error("Processing $file_name: ", $error);
            }
        };
        $log->info("Parsed YAML '$file_name' ok");
        my $key = $self->get_config_type_tag($type);
        if ( exists $this_config->{'type'} ) {
            push @config, $this_config;
        }
        elsif ( $type eq 'persister'
                and ref $this_config->{'persister'} eq 'ARRAY' ) {
            push @config, @{ $this_config->{'persister'} };
        }
        else {
            push @config, $this_config;
        }
    }
    return @config;
}

sub _translate_yaml {
    my ( $self, $type, $item ) = @_;

    unless ( $YAML_REQUIRED ) {
        require YAML;
        YAML->import( qw( Load LoadFile ) );
        $YAML_REQUIRED++;
    }

    if ( ref $item ) {
        return Load( $$item );
    }
    else {
        return LoadFile( $item );
    }
}

1;


__END__

=pod

=head1 NAME

Workflow::Config::YAML - Parse workflow configurations as YAML data structures

=head1 VERSION

This documentation describes version 2.09 of this package

=head1 SYNOPSIS

 # either of these is acceptable
 my $parser = Workflow::Config->new( 'yaml' );
 my $parser = Workflow::Config->new( 'yml' );

 my $conf = $parser->parse( 'condition',
                            'my_conditions.yml', 'your_conditions.yaml' );

=head1 DESCRIPTION

Implementation of configuration parser for serialized YAML data
structures from files/data. See L<Workflow::Config> for C<parse()>
description.

=head1 METHODS

=head2 parse

This method is required implemented by L<Workflow::Config>.

It takes two arguments:

=over

=item * a string indicating the type of configuration. For a complete list of
types please refer to L<Workflow::Config>

=item * a list of filenames containing at least a single file name

=back

The method returns a list of configuration parameters.

=head1 SEE ALSO

=over

=item * L<Workflow::Config>

=back

=head1 COPYRIGHT

Copyright (c) 2004-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
