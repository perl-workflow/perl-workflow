package Workflow::Config::YAML;

use warnings;
use strict;
use v5.14.0;
use parent qw( Workflow::Config );
use Log::Any qw( $log );
use Workflow::Exception qw( configuration_error );
use Carp qw(croak);
use Syntax::Keyword::Try;

$Workflow::Config::YAML::VERSION = '1.57';

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
