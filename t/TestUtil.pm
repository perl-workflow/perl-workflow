package TestUtil;

#!/usr/bin/perl

use strict;
use DateTime;
use Log::Log4perl qw( get_logger );

my $LOG_FILE  = 'workflow_tests.log';
my $CONF_FILE = 'log4perl.conf';
my $TEST_ROOT = '.';

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

sub init_factory {
    my $factory = Workflow::Factory->instance;
    $factory->add_config_from_file(
        workflow  => "$TEST_ROOT/workflow.xml",
        action    => "$TEST_ROOT/workflow_action.xml",
        condition => "$TEST_ROOT/workflow_condition.xml",
        validator => "$TEST_ROOT/workflow_validator.xml"
    );
}

# Initialize the logger and other resources

sub init {
    if ( -f $LOG_FILE ) {
        unlink( $LOG_FILE );
    }
    elsif ( -f "t/$LOG_FILE" ) {
        unlink( "t/$LOG_FILE" );
    }
    if ( -f $CONF_FILE ) {
        $TEST_ROOT = '.';
    }
    elsif ( -f "t/$CONF_FILE" ) {
        $TEST_ROOT = 't';
    }
    Log::Log4perl::init( "$TEST_ROOT/$CONF_FILE" );
}

init();

'I am true!';
