#!/usr/bin/perl

use strict;
use lib qw( ../lib );
use Data::Dumper qw( Dumper );
use Workflow::Config;

my ( $type, $file ) = @ARGV;
print Dumper( Workflow::Config->parse( $type, $file ) );
