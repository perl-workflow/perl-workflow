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

unlink( 'workflow.log' ) if ( -f 'workflow.log' );
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
            my $url = $request->uri;
            my ( $action ) = $url =~ m|^/(\w+)/|;
            my $cookie_header = $request->header( 'Cookie' );
            my %cookies_in = CGI::Cookie->parse( $cookie_header );
            my %cookies_out = ();
            my %params  = _parse_request( $request );
            my $status = RC_OK;
            my ( $content );

            if ( my $dispatch = $DISPATCH{ $action } ) {
                my $template_name = eval {
                    $dispatch->( $client, $request, \%cookies_in, \%cookies_out, \%params )
                };
                if ( $@ ) {
                    $params{error_msg} = $@;
                    $params{action}    = $action;
                    $status = RC_INTERNAL_SERVER_ERROR;
                    $template_name = 'error.tmpl';
                }
                if ( $params{workflow} ) {
                    $params{available_actions} = [ $params{workflow}->get_current_actions ];
                }
                $template->process( $template_name, \%params, \$content );
            }
            elsif ( ! $action ) {
                $template->process( 'index.tmpl', {}, \$content );
            }
            else {
                $content = "I don't know how to process action '$action'.";
                $status = RC_NOT_FOUND;
            }

            my $response = HTTP::Response->new( $status );
            $response->header( 'Content-Type' => 'text/html' );
            $response->content( $content );
            if ( scalar keys %cookies_out ) {
                my @cookie_obj = map {
                    CGI::Cookie->new( -name => $_, -value => $cookies_out{ $_ } )
                }  keys %cookies_out;
                my @cookie_values = map { $_->as_string } @cookie_obj;
                $response->header( 'Set-Cookie' => \@cookie_values );
                $log->info( "Set cookies: ", join( ' || ', @cookie_values ) );
            }
            $client->send_response( $response );
        }
        $client->close;
        undef( $client );
    }

    $log->info( "Stopping web daemon: ", scalar( localtime ) );
}

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

    # If they haven't entered data yet, redirect to the form for
    # entering it

    unless ( $params->{_action_data_entered} || ! $ACTION_DATA{ $action } ) {
        $params->{status_msg} =
            "Action cannot be executed until you enter its data";
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
    return 'workflow_history.tmpl';
}

sub _get_workflow {
    my ( $params, $cookies_in ) = @_;
    my $wf_id = $params->{workflow_id} || $cookies_in->{workflow_id};
    my $wf = FACTORY->fetch_workflow( 'Ticket', $wf_id );
    if ( $wf ) {
        $params->{workflow} = $wf;
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
