#!/usr/bin/perl -w

# $Id$

use strict;
use Data::Dumper;
use XML::Simple;

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
        ForceArray => [ 'extra_data', 'state', 'action',  'resulting_state', 'condition', 'observer' ],
        KeyAttr    => [],
    },
);


my $options = $XML_OPTIONS{ $ARGV[0] } || {};
my $data = XMLin( $ARGV[1], %{ $options } );

print Dumper $data;

exit(0);