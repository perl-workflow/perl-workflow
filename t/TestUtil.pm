package TestUtil;

#!/usr/bin/perl

use strict;
use DateTime;
use Log::Log4perl qw( get_logger );

my $LOG_FILE = 'workflow_tests.log';

########################################
# TICKET INFO

# Data for the initial ticket

my %TICKET = (
    current_user => 'Test User',
    creator      => 'Test User',
    subject      => 'A test ticket',
    description  => 'This is a test ticket used by the unit tests',
    type         => 'Feature',
    due_date     => DateTime->now,
);

sub get_new_ticket_info {
    return %TICKET;
}

sub set_new_ticket_context {
    my ( $class, $wf ) = @_;
    for ( keys %TICKET ) {
        $wf->context->param( $_ => $TICKET{ $_ } );
    }
}

# Initialize the logger and other resources

sub init {
    if ( -f $LOG_FILE ) {
        unlink( $LOG_FILE );
    }
    Log::Log4perl::init( 'log4perl.conf' );
}

init();

'I am true!';
