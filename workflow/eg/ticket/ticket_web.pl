#!/usr/bin/perl

# $Id$

use strict;
use CGI;
use CGI::Cookie;
use Cwd               qw( cwd );
use File::Spec::Functions;
use HTTP::Daemon;
use HTTP::Status;
use Log::Log4perl     qw( get_logger );
use Template;
use Workflow::Factory qw( FACTORY );

my $LOG_FILE = 'workflow.log';
if ( -f $LOG_FILE ) {
    my $mtime = (stat $LOG_FILE)[9];
    if ( time - $mtime > 600 ) { # 10 minutes
        unlink( $LOG_FILE );
    }
}
Log::Log4perl::init( 'log4perl.conf' );
my $log = get_logger();

$log->info( "Starting web daemon: ", scalar( localtime ) );

FACTORY->add_config_from_file( workflow  => 'workflow.xml',
                               action    => 'workflow_action.xml',
                               validator => 'workflow_validator.xml',
                               condition => 'workflow_condition.xml',
                               persister => 'workflow_persister.xml' );
$log->info( "Finished configuring workflow factory" );

my $template = Template->new( INCLUDE_PATH => catdir( cwd(), 'web_templates' ) );

my %DISPATCH = (
    create      => \&create_workflow,
    fetch       => \&fetch_workflow,
    history     => \&list_history,
    execute     => \&execute_action,
    login       => \&login,
);

my %ACTION_DATA = (
    TIX_NEW     => 'ticket_form.tmpl',
    TIX_COMMENT => 'ticket_comment.tmpl',
);

{
    my $d = HTTP::Daemon->new || die;
    print "Please contact me at [URL: ", $d->url, "]\n";
    while ( my $client = $d->accept ) {
        while ( my $request = $client->get_request ) {
            my $response = _handle_request( $client, $request );
            $client->send_response( $response );
        }
        $client->close;
        undef( $client );
    }

    $log->info( "Stopping web daemon: ", scalar( localtime ) );
}

sub _handle_request {
    my ( $client, $request ) = @_;

    my $cookie_header = $request->header( 'Cookie' );
    $log->debug( "Got cookie header from client '$cookie_header'" );
    my %cookies_in = CGI::Cookie->parse( $cookie_header );
    for ( keys %cookies_in ) {
        $cookies_in{ $_ } = $cookies_in{ $_ }->value;
    }

    $log->debug( "Mapped cookie header to: [",
                 join( '] [', map { "$_ = $cookies_in{ $_ }" }
                                  keys %cookies_in ), "]" );
    my %params  = _parse_request( $request );
    $log->debug( "Got the following parameter names: ",
                 join( ', ', keys %params ) );

    # Also set the cookies as parameters, but don't stomp
    for ( keys %cookies_in ) {
        $params{ $_ } = $cookies_in{ $_ } unless ( $params{ $_ } );
    }

    my $url = $request->uri;
    my ( $action ) = $url =~ m|^/(\w+)/|;
    $log->debug( "Trying to dispatch action '$action'" );

    my $status = RC_OK;
    my $content = '';
    my %cookies_out = ();

    if ( my $dispatch = $DISPATCH{ $action } ) {
        $log->debug( "Dispatch method found for '$action', executing..." );
        my $template_name = eval {
            $dispatch->( $client, $request, \%cookies_in, \%cookies_out, \%params )
        };
        if ( $@ ) {
            $log->error( "Caught error executing '$action': $@" );
            $params{error_msg} = $@;
            $params{action}    = $action;
            $status = RC_INTERNAL_SERVER_ERROR;
            $template_name = 'error.tmpl';
        }
        if ( $params{workflow} ) {
            $log->debug( "Action set 'workflow' in parameters, getting ",
                         "current actions from it for menu..." );
            $params{available_actions} = [ $params{workflow}->get_current_actions ];
        }
        $log->debug ( "Processing template '$template_name'..." );
        eval {
            $template->process( $template_name, \%params, \$content )
                || die "Cannot process template '$template_name': ",
                       $template->error(), "\n";
        };
        if ( $@ ) {
            $log->error( $@ );
            $content = $@;
            $status = RC_INTERNAL_SERVER_ERROR;
        }
        else {
            $log->debug( "Processed template ok" );
        }
    }
    elsif ( ! $action ) {
        $log->debug( "Processing index template since no action given" );
        $template->process( 'index.tmpl', {}, \$content );
    }
    else {
        $log->error( "No dispatch found for action '$action'" );
        $content = "I don't know how to process action '$action'.";
        $status = RC_NOT_FOUND;
    }

    my $response = HTTP::Response->new( $status );
    $response->header( 'Content-Type' => 'text/html' );
    $response->content( $content );
    if ( scalar keys %cookies_out ) {
        my @values = ();
        while ( my ( $name, $value ) = each %cookies_out ) {
            my $obj = CGI::Cookie->new( -name  => $name,
                                        -value => $value );
            my $cookie = $obj->as_string;
            push @values, $cookie;
            $log->debug( "Adding cookie: '$cookie'" );
        }
        $response->header( 'Set-Cookie' => \@values );
    }
    return $response;
}


########################################
# DISPATCH MAPPINGS
#
# Each of these routines returns a template name, stuffing data used
# by the template into \%params and any outbound cookies into
# \%cookies_out.

sub create_workflow {
    my ( $client, $request, $cookies_in, $cookies_out, $params ) = @_;
    my $wf = FACTORY->create_workflow( 'Ticket' );
    $params->{workflow} = $wf;
    $cookies_out->{workflow_id} = $wf->id;
    return 'workflow_created.tmpl';
}

sub fetch_workflow {
    my ( $client, $request, $cookies_in, $cookies_out, $params ) = @_;
    my $wf = _get_workflow( $params, $cookies_in );
    $cookies_out->{workflow_id} = $wf->id;
    return 'workflow_fetched.tmpl';
}

sub list_history {
    my ( $client, $request, $cookies_in, $cookies_out, $params ) = @_;
    my $wf = _get_workflow( $params, $cookies_in );
    my @history = $wf->get_history();
    $params->{history_list} = \@history;
    return 'workflow_history.tmpl';
}

sub execute_action {
    my ( $client, $request, $cookies_in, $cookies_out, $params ) = @_;
    my $wf = _get_workflow( $params, $cookies_in );

    my $action = $params->{action};
    unless ( $action ) {
        die "To execute an action you must specify an action name!\n";
    }

    # If they haven't entered data yet, add the fields (as a map) to
    # the parameters and redirect to the form for entering it

    unless ( $params->{_action_data_entered} || ! $ACTION_DATA{ $action } ) {
        $params->{status_msg} =
            "Action cannot be executed until you enter its data";
        my @fields = $wf->get_action_fields( $action );
        my %by_name = map { $_->name => $_ } @fields;
        $params->{ACTION_FIELDS} = \%by_name;
        return $ACTION_DATA{ $action };
    }

    # Otherwise, set the user data directly into the workflow context...
    $wf->context->param( $params );

    # ...and execute the action
    eval { $wf->execute_action( $params->{action} ) };

    # ...if we catch a condition/validation exception, display the
    # error and go back to the data entry form

    if ( $@ && ( $@->isa( 'Workflow::Exception::Condition' ) ||
                 $@->isa( 'Workflow::Exception::Validation' ) ) ) {
        $log->error( "One or more conditions not met to execute action: $@; ",
                     "redirecting to form" );
        $params->{error_msg} = "Failed to execute action: $@";
        return $ACTION_DATA{ $action };
    }
    $params->{status_msg} = "Action '$action' executed ok";
    return list_history( $client, $request, $cookies_in, $cookies_out, $params );
}

sub login {
    my ( $client, $request, $cookies_in, $cookies_out, $params ) = @_;
    if ( $params->{current_user} ) {
        $cookies_out->{current_user} = $params->{current_user};
    }
    else {
        $params->{error_msg} = "Please specify a login name I can use!";
    }
    return 'index.tmpl';
}

sub _get_workflow {
    my ( $params, $cookies_in ) = @_;
    return $params->{workflow} if ( $params->{workflow} );
    my $log = get_logger();
    my $wf_id = $params->{workflow_id} || $cookies_in->{workflow_id};
    unless ( $wf_id ) {
        die "No workflow ID given! Please fetch a workflow or create ",
            "a new one.\n";
    }
    $log->debug( "Fetching workflow with ID '$wf_id'" );
    my $wf = FACTORY->fetch_workflow( 'Ticket', $wf_id );
    if ( $wf ) {
        $log->debug( "Workflow found, current state is '", $wf->state, "'" );
        $params->{workflow} = $wf;
    }
    else {
        $log->warn( "No workflow found with ID '$wf_id'" );
        die "No workflow found with ID '$wf_id'\n";
    }
    return $wf;
}

########################################
# PARAMETER PARSING

sub _parse_request {
    my ( $request ) = @_;
    my $method = $request->method;
    my $content_type = $request->content_type;
    if ( $method eq 'GET' || $method eq 'HEAD' ) {
        return _assign_args( CGI->new( $request->uri->equery ) );
    }
    elsif ( $method eq 'POST' ) {
        if ( ! $content_type
                 || $content_type eq "application/x-www-form-urlencoded" ) {
            return _assign_args( CGI->new( $request->content ) );
        }
    }
    die "Unsupported [Method: $method] [Content Type: $content_type]";
}

sub _assign_args {
    my ( $cgi ) = @_;
    my %params = ();
    foreach my $name ( $cgi->param() ) {
        my @values = $cgi->param( $name );
        if ( scalar @values > 1 ) {
            $params{ $name } = \@values;
        }
        else {
            $params{ $name } = $values[0];
        }
    }
    return %params;
}
