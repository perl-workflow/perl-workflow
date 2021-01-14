package TestPersisterElsewhere;

use strict;
use warnings;
use base qw( Workflow::Persister::DBI );

sub create_handle { return undef; }

1;
