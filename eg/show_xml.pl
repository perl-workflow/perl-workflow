#!/usr/bin/perl

use strict;
use Config::Auto;
use Data::Dumper qw( Dumper );

$Data::Dumper::Indent = 1;

my $conf = Config::Auto::parse( $ARGV[0] );
print Dumper( $conf );
