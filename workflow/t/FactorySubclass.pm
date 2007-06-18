package FactorySubclass;

use strict;
use vars qw($VERSION);
use base qw( Workflow::Factory );

$VERSION = '0.01';

sub crazy_method { return "Altoid Fever!" }

1;
