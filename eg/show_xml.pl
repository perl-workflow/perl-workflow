#!/usr/bin/perl

use strict;
use Workflow::Config;
use Data::Dumper qw( Dumper );

$Data::Dumper::Indent = 1;

my @conf = Workflow::Config->_translate_xml( $ARGV[0], $ARGV[1] );
print Dumper( $conf[0] );
