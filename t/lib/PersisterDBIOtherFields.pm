package PersisterDBIOtherFields;

use warnings;
use strict;
use parent qw( Workflow::Persister::DBI );


sub get_workflow_fields {
    return qw( w1 w2 w3 w4 );
}

sub get_history_fields {
    return qw( h1 h2 h3 h4 h5 h6 h7 );
}

1;

