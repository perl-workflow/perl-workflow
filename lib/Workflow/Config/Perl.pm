package Workflow::Config::Perl;

use warnings;
use strict;
use v5.14.0;
use parent qw( Workflow::Config );
use Log::Any qw( $log );
use Workflow::Exception qw( configuration_error );
use Data::Dumper qw( Dumper );
use English qw( -no_match_vars );

$Workflow::Config::Perl::VERSION = '2.04';

sub parse {
    my ( $self, $type, @items ) = @_;

    $self->_check_config_type($type);

    if ( !scalar @items ) {
        return @items;
    }

    my @config_items = Workflow::Config::_expand_refs(@items);
    return () unless ( scalar @config_items );

    my @config = ();
    foreach my $item (@config_items) {
        my ( $file_name, $method );
        if ( ref $item ) {
            $method    = '_translate_perl';
            $file_name = '[scalar ref]';
        }

        # $item is a filename...
        else {
            $method    = '_translate_perl_file';
            $file_name = $item;
        }
        $log->info("Will parse '$type' Perl config file '$file_name'");
        my $this_config = $self->$method( $type, $item );

        #warn "This config looks like:";
        #warn Dumper (\$this_config);
        $log->info("Parsed Perl '$file_name' ok");

        if ( exists $this_config->{'type'} ) {
            $log->debug("Adding typed configuration for '$type'");
            push @config, $this_config;
        } elsif ( $type eq 'persister'
            and ref $this_config->{$type} eq 'ARRAY' )
        {

            # This special exception for persister is required because
            # the config design for persisters was different from the
            # other config types. It didn't have a top level 'persister'
            # element. For backward compatibility, I'm adding this
            # exception here.
            $log->debug("Adding multiple configurations for '$type'");
            push @config, @{ $this_config->{$type} };
        } else {
            $log->debug("Adding single configuration for '$type'");
            push @config, $this_config;
        }
    }
    return @config;
}

sub _translate_perl_file {
    my ( $class, $type, $file ) = @_;

    local $INPUT_RECORD_SEPARATOR = undef;
    open( CONF, '<', $file )
        || configuration_error "Cannot read file '$file': $!";
    my $config = <CONF>;
    close(CONF) || configuration_error "Cannot close file '$file': $!";
    my $data = $class->_translate_perl( $type, $config, $file );
    $log->debug( sub { "Translated '$type' '$file' into: ", Dumper($data) } );
    return $data;
}

sub _translate_perl {
    my ( $class, $type, $config, $file ) = @_;

    no strict 'vars';
    my $data;
    my $error;
    my $warnings = '';
    my $success = do {
        local $@;

        local $SIG{__WARN__} = sub { $warnings .= $_[0] };
        my $rv = eval "\$data = do { $config }; 1;";
        $error = $EVAL_ERROR;
        $rv;
    };
    if ($warnings) {
        $warnings =~ s/\r?\n/\\n/g; # don't log line-endings
        $log->warn( 'Config evaluation warned: ', $warnings );
    }
    if (not $success) {
        configuration_error "Cannot evaluate perl data structure ",
            "in '$file': $error";
    }
    return $data;
}

1;

__END__

=pod

=head1 NAME

Workflow::Config::Perl - Parse workflow configurations as Perl data structures

=head1 VERSION

This documentation describes version 2.04 of this package

=head1 SYNOPSIS

 # either of these is acceptable
 my $parser = Workflow::Config->new( 'perl' );
 my $parser = Workflow::Config->new( 'pl' );

 my $conf = $parser->parse( 'condition',
                            'my_conditions.pl', 'your_conditions.perl' );

=head1 DESCRIPTION

Implementation of configuration parser for serialized Perl data
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
