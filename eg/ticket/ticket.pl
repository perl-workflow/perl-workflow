#!/usr/bin/perl

use strict;
use App::Ticket;
use DBI;
use Getopt::Long      qw( GetOptions );
use Log::Log4perl     qw( get_logger );
use Workflow::Factory qw( FACTORY );

require '../../t/TestDBUtil.pm';

$| = 1;

my $LOG_FILE = 'workflow.log';
if ( -f $LOG_FILE ) {
    my $mtime = (stat $LOG_FILE)[9];
    if ( time - $mtime > 600 ) { # 10 minutes
        unlink( $LOG_FILE );
    }
}
Log::Log4perl::init( 'log4perl.conf' );
my $log = get_logger();

$log->info( "Starting: ", scalar( localtime ) );

my ( $OPT_db_init, $OPT_db_type );
GetOptions( 'db'       => \$OPT_db_init,
            'dbtype=s' => \$OPT_db_type );
$OPT_db_type ||= 'sqlite';

my $DB_FILE = 'ticket.db';

if ( $OPT_db_init ) {
  TestDBUtil::create_tables({
			     db_type => $OPT_db_type,
			     db_file => $DB_FILE,
			    });
  print "Created database and tables ok\n";
  exit();
}

FACTORY->add_config_from_file( workflow  => 'workflow.xml',
                               action    => 'workflow_action.xml',
                               validator => 'workflow_validator.xml',
                               condition => 'workflow_condition.xml',
                               persister => 'workflow_persister.xml' );
$log->info( "Finished configuring workflow factory" );

my ( $wf, $user, $ticket );

my %responses = (
    wf            => [
        "Create/retrieve a workflow",
        "Create: 'wf Ticket'; retrieve (ID == 4): 'wf Ticket 4'",
        \&get_workflow,
    ],
    state         => [
        'Get current state of active workflow',
        "'state'",
        \&get_current_state,
    ],
    actions       => [
        'Get current actions of active workflow',
        "'actions'",
        \&get_current_actions,
    ],
    action_data   => [
        "Display data required for a particular action",
        "'action_data FOO_ACTION'",
        \&get_action_data,
    ],
    enter_data    => [
        "Interactively enter data required for an action and place it in context",
        "'enter_data FOO_ACTION'",
        \&prompt_action_data,
    ],
    context       => [
        "Set data into the context, or with no args show current context",
        "'context myvar myvalue'",
        \&set_context,
    ],
    context_clear => [
        'Clear data out of context',
        "'context_clear'",
        \&clear_context,
    ],
    execute       => [
        'Execute an action; data for the action should be in context',
        "'execute FOO_ACTION'",
        \&execute_action,
    ],
    ticket        => [
        'Fetch a ticket and put it into the context, or show contents of current ticket',
        "'ticket 1'; 'ticket'",
        \&use_ticket,
    ],
    history       => [
        'Show the history of a workflow',
        "'history'",
        \&show_history,
    ],
    help          => [
        'List all commands and a brief description',
        "'help'",
        \&list_commands,
    ],
   quit          => [
       'Exit the application',
       "'quit'",
       sub { exit(0) },
   ],
);

while ( 1 ) {
    my $full_response = get_response( "TicketServer: " );
    next unless ( $full_response );
    my @args = split /\s+/, $full_response;
    my $response = shift @args;
    if ( my $info = $responses{ $response } ) {
        eval { $info->[2]->( @args ) };
        print "Caught error: $@\n" if ( $@ );
    }
    else {
        print "Response '$response' not valid; available options are:\n",
              "   ", join( ', ', sort keys %responses  ), "\n";
    }
}

print "All done!\n";
$log->info( "Stopping: ", scalar( localtime ) );
exit();

sub prompt_action_data {
    my ( @action_name_info ) = @_;
    _check_wf();
    my $action_name = join ' ', @action_name_info;
    unless ( $action_name ) {
        die "Command 'action_data' requires 'action_name' specified\n";
    }
    my @action_fields = $wf->get_action_fields( $action_name );
    foreach my $field ( @action_fields ) {
        if ( $wf->context->param( $field->name ) ) {
            print "Field '", $field->name, "' already exists in context, skipping...\n";
            next;
        }
        my @values = $field->get_possible_values;
        my ( $prompt );
        if ( scalar @values ) {
            $prompt = sprintf( "Value for field '%s' (%s)\n   %s\n   Values: %s\n-> ",
                               $field->name, $field->type, $field->description,
                               join( ', ', map { $_->{value} } @values ) );
        }
        else {
            $prompt = sprintf( "Value for field '%s' (%s)\n   %s\n-> ",
                               $field->name, $field->type, $field->description );
        }
        my $value = get_response( $prompt );
        if ( $value ) {
            $wf->context->param( $field->name, $value );
        }
    }
    print "All data entered\n";
}

sub show_history {
    _check_wf();
    print "Workflow history: \n";
    foreach my $h ( $wf->get_history() ) {
        printf( "  (%5s) %s %s %s: %s\n",
                $h->user, $h->date->strftime( '%Y-%m-%d %H:%M' ),
                $h->state, $h->action, $h->description );
    }
}

sub use_ticket {
    my ( $id ) = @_;
    _check_wf();
    my $context = $wf->context();
    if ( ! $id and my $t = $context->param( 'ticket' ) ) {
        print "Contents of ticket '", $t->ticket_id, "': \n";
        foreach my $field ( $t->get_fields ) {
            next if ( $field eq 'ticket_id' );
            my $value = $ticket->$field();
            if ( ref $value and $value->isa( 'DateTime' ) ) {
                $value = $value->strftime( '%Y-%m-%d %H:%M' );
            }
            printf( "  %12s: %s\n", $field, $value );
        }
    }
    elsif ( ! $id ) {
        die "Command 'ticket' requires the ID of the ticket you wish to use\n";
    }
    else {
        $ticket = App::Ticket->fetch( $id );
        print "Ticket '$id' fetched wih subject '", $ticket->subject, "'\n";
        $wf->context->param( ticket => $ticket );
    }
}

sub get_action_data {
    my $action_name = join( ' ', @_ );
    _check_wf();
    unless ( $action_name ) {
        die "Command 'action_data' requires 'action_name' specified\n";
    }
    my @action_fields = $wf->get_action_fields( $action_name );
    print "Data for action '$action_name':\n";
    foreach my $field ( @action_fields ) {
        my @values = $field->get_possible_values;
        if ( scalar @values ) {
        printf( "(%s) (%s) %s [%s]: %s\n",
                $field->type, $field->is_required, $field->name,
                join( '|', map { $_->{value} } @values ),
                $field->description );
        }
        else {
            printf( "(%s) (%s) %s: %s\n",
                    $field->type, $field->is_required, $field->name,
                    $field->description );
        }
    }
}

sub set_context {
    my ( $name, @values ) = @_;
    _check_wf();
    if ( $name and scalar @values ) {
        $wf->context->param( $name, join( ' ', @values ) );
        print "Context parameter '$name' set to '", $wf->context->param( $name ), "'\n";
    }
    else {
        my $params = $wf->context->param;
        print "Current context contents: \n";
        while ( my ( $k, $v ) = each %{ $params } ) {
            if ( ref( $v ) ) {
                $v = 'isa ' . ref( $v );
            }
            printf( "  %12s: %s\n", $k, $v );
        }
    }
}

sub clear_context {
    _check_wf();
    $wf->context->clear_params;
    print "Context cleared\n";
}

sub list_commands {
    print "Available commands:\n\n";
    foreach my $cmd ( sort keys %responses ) {
        printf( "%s\n  Example: %s\n  %s\n",
                "$cmd:",
                $responses{ $cmd }->[1],
                $responses{ $cmd }->[0] );
    }
    print "\n";
}

sub get_current_state {
    _check_wf();
    print "Current state of workflow is '", $wf->state, "'\n";
}

sub get_current_actions {
    _check_wf();
    print "Actions available in state '", $wf->state, "': ",
          join( ', ', $wf->get_current_actions ), "\n";
}

sub show_context {
    _check_wf();
}

sub execute_action {
    _check_wf();
    my $action_name = join( ' ', @_ );
    unless ( $action_name ) {
        die "Command 'execute_action' requires you to set 'action_name'\n";
    }
    $wf->execute_action( $action_name );
}

sub get_workflow {
    my ( $type, $id ) = @_;
    if ( $id ) {
        print "Fetching existing workflow of type '$type' and ID '$id'...\n";
        $wf = FACTORY->fetch_workflow( $type, $id );
    }
    else {
        print "Creating new workflow of type '$type'...\n";
        $wf = FACTORY->create_workflow( $type );
    }
    print "Workflow of type '", $wf->type, "' available with ID '", $wf->id, "'\n";
}

sub _check_wf {
    unless ( $wf ) {
        die "First create or fetch a workflow!\n";
    }
}


# Generic routine to read a response from the command-line (defaults,
# etc.) Note that return value has whitespace at the end/beginning of
# the routine trimmed.

sub get_response {
    my ( $msg ) = @_;
    print $msg;
    my $response = <STDIN>;
    chomp $response;
    $response =~ s/^\s+//;
    $response =~ s/\s+$//;
    return $response;
}
