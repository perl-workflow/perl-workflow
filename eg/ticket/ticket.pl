#!/usr/bin/perl

use strict;
use lib qw( ../../../lib );
use App::Ticket;
use DBI;
use Getopt::Long      qw( GetOptions );
use Log::Log4perl     qw( get_logger );
use Workflow::Factory qw( FACTORY );

Log::Log4perl::init( 'log4perl.conf' );

my ( $OPT_db_init );
GetOptions( 'db' => \$OPT_db_init );

my $DB_FILE = 'ticket.db';

if ( $OPT_db_init ) {
    create_tables();
    print "Created database and tables ok\n";
    exit();
}

FACTORY->add_config_from_file( workflow  => 'workflow.xml',
                               action    => 'workflow_action.xml',
                               validator => 'workflow_validator.xml',
                               condition => 'workflow_condition.xml',
                               persister => 'workflow_persister.xml' );
my ( $wf, $user, $ticket );


my %responses = (
   cmd           => \&list_commands,
   wf            => \&get_workflow,
   state         => \&get_current_state,
   actions       => \&get_current_actions,
   action_data   => \&get_action_data,
   enter_data    => \&prompt_action_data,
   context       => \&set_context,
   context_clear => \&clear_context,
   context_show  => \&show_context,
   execute       => \&execute_action,
   ticket        => \&use_ticket,
   break         => sub {},
   quit          => sub {},
);

while ( 1 ) {
    my $full_response = get_response( "TicketServer: " );
    my @args = split /\s+/, $full_response;
    my $response = shift @args;
    last if ( $response =~ /^(break|quit)$/ );
    if ( my $sub = $responses{ $response } ) {
        eval { $sub->( @args ) };
        print "Caught error: $@\n" if ( $@ );
    }
    else {
        print "Response '$response' not valid; available options are:\n",
              "   ", join( ', ', sort keys %responses  ), "\n";
    }
}

print "All done!\n";

exit();

sub prompt_action_data {
    my ( $action_name ) = @_;
    _check_wf();

    unless ( $action_name ) {
        die "Command 'enter_action_data' requires 'action_name' specified\n";
    }
    my @action_fields = $wf->get_action_fields( $action_name );
    foreach my $field ( @action_fields ) {
        if ( $wf->context->param( $field->name ) ) {
            print "Field '", $field->name, "' already exists in context, skipping...\n";
            next;
        }
        my $value = get_response( "Value for field '", $field->name, "' ",
                                  "(", $field->type, ")\n" .
                                  "   ", $field->description, "\n",
                                  "data: " );
        if ( $value ) {
            $wf->context->param( $field->name, $value );
        }
    }
    print "All data entered\n";
}

sub use_ticket {
    my ( $id ) = @_;
    _check_wf();
    unless ( $id ) {
        die "Command 'use_ticket' requires the ID of the ticket you wish to use\n";
    }
    $ticket = App::Ticket->fetch( $id );
    print "Ticket '$id' fetched wih subject '$ticket->{subject}\n";
    $wf->context->param( ticket => $ticket );
}

sub get_action_data {
    my ( $action_name ) = @_;
    _check_wf();
    unless ( $action_name ) {
        die "Command 'action_data' requires 'action_name' specified\n";
    }
    my @action_fields = $wf->get_action_fields( $action_name );
    print "Data for action '$action_name':\n";
    foreach my $field ( @action_fields ) {
        print "($field->{type})  $field->{name}: $field->{description}\n";
    }
}

sub set_context {
    my ( $name, @values ) = @_;
    _check_wf();
    $wf->context->param( $name, join( ' ', @values ) );
    print "Context parameter '$name' set to '", $wf->context->param( $name ), "'\n";
}

sub clear_context {
    _check_wf();
    $wf->context->clear_params;
    print "Context cleared\n";
}

sub list_commands {
    print "Available commands: ", join( ', ', keys %responses ), "\n";
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

sub _check_wf {
    unless ( $wf ) {
        die "First create or fetch a workflow!\n";
    }
}

sub show_context {
    _check_wf();
    my $params = $wf->context->param;
    print "Contents of current context: \n";
    while ( my ( $k, $v ) = each %{ $params } ) {
        if ( ref( $v ) ) {
            $v = 'isa ' . ref( $v );
        }
        print "$k: $v\n";
    }
}

sub execute_action {
    _check_wf();
    my ( $action_name ) = @_;
    unless ( $action_name ) {
        die "Command 'execute_action' requires you to set 'action_name'\n";
    }
    $wf->execute_action( $action_name );
}

sub get_workflow {
    my ( $type, $id ) = @_;
    if ( $id ) {
        print "Fetching existing workflow of type '$type' and ID '$id'...\n";
        $wf = FACTORY->get_workflow( $type, $id );
    }
    else {
        print "Creating new workflow of type '$type'...\n";
        $wf = FACTORY->get_workflow( $type );
    }
    print "Workflow of type '", $wf->type, "' available with ID '", $wf->id, "'\n";
}


########################################
# DB INIT

sub create_tables {
    my $log = get_logger();
    if ( -f $DB_FILE ) {
        $log->info( "Removing old database file..." );
        unlink( $DB_FILE );
    }
    my $dbh = DBI->connect( "DBI:SQLite:dbname=$DB_FILE", '', '' )
                  || die "Cannot create database: $DBI::errstr\n";
    $dbh->{RaiseError} = 1;
    $log->info( "Connected to database ok" );
    my @tables = ( read_tables( '../../struct/workflow_sqlite.sql' ),
                   read_tables( 'ticket.sql' ) );
    for ( @tables ) {
        next if ( /^\s*$/ );
        $log->debug( "Creating table:\n$_" );
        eval { $dbh->do( $_ ) };
        if ( $@ ) {
            die "Failed to create table\n$_\n$@\n";
        }
    }
    $log->info( 'Created tables ok' );
}

########################################
# I/O

sub read_tables {
    my ( $file ) = @_;
    my $table_file = read_file( $file );
    return split( ';', $table_file );
}

sub read_file {
    my ( $file ) = @_;
    local $/ = undef;
    open( IN, '<', $file ) || die "Cannot read '$file': $!";
    my $content = <IN>;
    close( IN );
    return $content;
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
