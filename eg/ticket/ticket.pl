#!/usr/bin/perl

use strict;
use lib qw( ../../../lib );
use Common;
use Getopt::Long qw( GetOptions );
use Log::Log4perl qw( get_logger );
use SPOPS::Initialize;
use WorkflowContext;
use WorkflowFactory qw( FACTORY );

Log::Log4perl::init( 'log4perl.conf' );

my ( $OPT_db_init );
GetOptions( 'db'   => \$OPT_db_init );

if ( $OPT_db_init ) {
    create_tables();
}

initialize_spops();

my $factory = FACTORY->add_config({ workflow  => 'workflow.ini',
                                    action    => 'workflow_action.ini',
                                    validator => 'workflow_validator.ini',
                                    condition => 'workflow_condition.ini' });
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
        print "Response '$response' not valid; available options: ",
              join( ', ', sort keys %responses  ), "\n";
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
        if ( $wf->context->param( $field ) ) {
            print "Field '$field' already exists in context, skipping...\n";
            next;
        }
        my $value = get_response( "Value for field '$field->{name}' ($field->{type})\n" .
                                  "   $field->{description}\ndata: " );
        if ( $value ) {
            $wf->context->param( $field->{name}, $value );
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
    $ticket = Ticket->fetch( $id );
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

    if ( $name eq 'user' ) {
        my ( $user );
        if ( $values[0] =~ /^\d+$/ ) {
            $user = User->fetch( $values[0] );
        }
        else {
            $user = User->new({ name => $values[0] } )->save();
        }
        $wf->context->param( 'current_user', $user );
        print "Context parameter 'current_user' set to '$user->{name} ($user->{user_id})'\n";
    }
    else {
        $wf->context->param( $name, join( ' ', @values ) );
        print "Context parameter '$name' set to '", $wf->context->param( $name ), "'\n";
    }
#    else {
#        die "Don't know how to handle multiple values with '$values[0]' yet\n";
#    }
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
        $wf = $factory->get_workflow( $type, $id );
    }
    else {
        print "Creating new workflow of type '$type'...\n";
        $wf = $factory->get_workflow( $type );
    }
    print "Workflow of type '", $wf->type, "' available with ID '", $wf->id, "'\n";
}


sub _old_stuff {
    my @action_fields = $wf->get_action_fields( 'TIX_NEW' );

    print "Fields necessary for TIX_NEW:\n";
    foreach my $field ( @action_fields ) {
        print "($field->{type})  $field->{name}: $field->{description}\n";
    }

    eval {
        $wf->execute_action( 'TIX_NEW' );
    };

    print "ID of saved workflow is: ", $wf->id, " with state '", $wf->state, "'\n";

    eval {
        $wf->execute_action( 'TIX_EDIT' );
        print "New state of workflow after starting edit: ", $wf->state, "\n";
    };

    if ( $@ ) {
        print "Cannot execute action: $@\n";
    }

    print "\n";
}


sub create_tables {
    my $log = get_logger();
    my $db = Common->global_datasource_handle;
    eval {
        $db->do( 'DROP TABLE ticket' );
        $db->do( 'DROP TABLE user' );
        $db->do( 'DROP TABLE workflow' );
        $db->do( 'DROP TABLE workflow_ticket' );
    };
    $log->debug( 'Dropped tables ok' );
    eval {
        $db->do( read_file( 'ticket.sql' ) );
        $db->do( read_file( 'user.sql' ) );
        $db->do( read_file( 'workflow.sql' ) );
        $db->do( read_file( 'workflow_ticket.sql' ) );
    };
    if ( $@ ) {
        die "Failed to create tables: $@";
    }
    $log->debug( 'Created tables ok' );
}

sub read_file {
    my ( $file ) = @_;
    local $/ = undef;
    open( IN, '<', $file ) || die "Cannot read '$file': $!";
    my $content = <IN>;
    close( IN );
    return $content;
}

sub initialize_spops {
    my %conf = (
        ticket => {
            class => 'Ticket',
            isa => [ qw/ Common SPOPS::DBI::MySQL SPOPS::DBI / ],
            field_discover => 'yes',
            id_field => 'ticket_id',
            increment_field => 1,
            rules_from => [ 'SPOPS::Tool::DBI::DiscoverField' ],
            base_table => 'ticket',
        },
        user => {
            class => 'User',
            isa => [ qw/ Common SPOPS::DBI::MySQL SPOPS::DBI / ],
            field_discover => 'yes',
            id_field => 'user_id',
            increment_field => 1,
            rules_from => [ 'SPOPS::Tool::DBI::DiscoverField' ],
            base_table => 'user',
        },
        workflow => {
            class => 'WorkflowPersist',
            isa => [ qw/ Common SPOPS::DBI::MySQL SPOPS::DBI / ],
            field_discover => 'yes',
            id_field => 'workflow_id',
            increment_field => 1,
            rules_from => [ 'SPOPS::Tool::DBI::DiscoverField' ],
            base_table => 'workflow',
        },
    );
    SPOPS::Initialize->process({ config => \%conf });
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
