#!/usr/bin/perl

# $Id$

use strict;
use App::Web;
use CGI;
use CGI::Cookie;
use Cwd               qw( cwd );
use File::Spec::Functions;
use HTTP::Daemon;
use HTTP::Status;
use Log::Log4perl     qw( get_logger );
use Workflow::Factory qw( FACTORY );

App::Web->init_logger();
my $log = get_logger();

$log->info( "Starting web daemon: ", scalar( localtime ) );

App::Web->init_factory();
App::Web->init_url_mappings( 'web_workflow.xml' );

{
    my $d = HTTP::Daemon->new
                || die "Failed to initialize daemon: $!";
    $log->info( "Initialized daemon at URL '", $d->url, "'" );
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
    my $cgi = _create_cgi( $request );
    my $dispatcher = App::Web->create_dispatcher(
        cookie_text => $cookie_header,
        cgi         => $cgi,
    );

    my $url = $request->uri;
    my ( $action ) = $url =~ m|^/(\w+)/|;
    $log->debug( "Trying to dispatch action '$action'" );

    my $status = RC_OK;
    my $content = '';

    if ( $dispatcher->is_dispatchable( $action ) ) {
        $log->debug( "Action '$action' can be dispatched, executing..." );
        my $template_name = eval {
            $dispatcher->run( $action );
        };
        if ( $@ ) {
            $log->error( "Caught error executing '$action': $@" );
            $dispatcher->param( error_msg => $@ );
            $dispatcher->param( action    => $action );
            $status = RC_INTERNAL_SERVER_ERROR;
            $template_name = 'error.tmpl';
        }

        if ( my $wf = $dispatcher->param( 'workflow' ) ) {
            $log->debug( "Action set 'workflow' in parameters, getting ",
                         "current actions from it for menu..." );
            $dispatcher->param(
                available_actions => [ $wf->get_current_actions ] );
        }
        $log->debug ( "Processing template '$template_name'..." );
        eval {
            $content = $dispatcher->process_template( $template_name );
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
        $content = $dispatcher->process_template( 'index.tmpl' );
    }
    else {
        $log->error( "No dispatch found for action '$action'" );
        $content = "I don't know how to process action '$action'.";
        $status = RC_NOT_FOUND;
    }

    my $response = HTTP::Response->new( $status );
    $response->header( 'Content-Type' => 'text/html' );
    $response->content( $content );
    $response->header( 'Set-Cookie' => $dispatcher->cookie_out_as_objects );
    return $response;
}


########################################
# PARAMETER PARSING

sub _create_cgi {
    my ( $request ) = @_;
    my $method = $request->method;
    my $content_type = $request->content_type;
    if ( $method eq 'GET' || $method eq 'HEAD' ) {
        return CGI->new( $request->uri->equery );
    }
    elsif ( $method eq 'POST' ) {
        if ( ! $content_type
                 || $content_type eq "application/x-www-form-urlencoded" ) {
            return CGI->new( $request->content );
        }
    }
    die "Unsupported [Method: $method] [Content Type: $content_type]";
}

