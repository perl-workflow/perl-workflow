#!/usr/bin/perl

use strict;

use lib qw(
    /Users/cwinters/work/workflow/lib
    /Users/cwinters/work/Class-Factory/lib
    /Users/cwinters/work/Class-Observable/lib
);

use App::Web;
use CGI;
use HTTP::Status;
use Log::Log4perl qw( get_logger );

my ( $log );

{
    App::Web->init_logger();
    App::Web->init_factory();
    App::Web->init_url_mappings( 'web_workflow.xml' );

    $log = get_logger();

    my $cgi = CGI->new();
    my $cookie_text = $cgi->raw_cookie;
    my $script_name = $cgi->script_name;
    my $path_info   = $cgi->path_info;
    $log->info( "Called script with name '$script_name' and ",
                "path '$path_info'" );

    my $dispatcher = App::Web->create_dispatcher(
        cgi         => $cgi,
        cookie_text => $cookie_text,
        base_url    => $cgi->script_name,
    );
    my ( $action_name ) = $path_info =~ m|^/(\w+)/|;
    $log->is_info &&
        $log->info( "Found action name '$action_name' from URL" );

    # default status
    my $status = RC_OK;

    # page content goes here
    my ( $content );

    # hold the template to process here
    my ( $template_name );


    eval {
        if ( $dispatcher->is_dispatchable( $action_name ) ) {
            $log->debug( "Action '$action_name' can be dispatched, executing..." );
            my $template_name = eval {
                $dispatcher->run( $action_name );
            };
            if ( $@ ) {
                $log->error( "Caught error executing '$action_name': $@" );
                $dispatcher->param( error_msg => $@ );
                $dispatcher->param( action    => $action_name );
                $status = RC_INTERNAL_SERVER_ERROR;
                $template_name = 'error.tmpl';
            }
            elsif ( my $wf = $dispatcher->param( 'workflow' ) ) {
                $log->debug( "Action set 'workflow' in parameters, getting ",
                             "current actions from it for menu..." );
                $dispatcher->param(
                    available_actions => [ $wf->get_current_actions ] );
            }
            $content = $dispatcher->process_template( $template_name );
        }
        elsif ( ! $action_name ) {
            $log->debug( "Processing index template since no action given" );
            $content = $dispatcher->process_template( 'index.tmpl' );
        }
        else {
            $log->error( "No dispatch found for action '$action_name'" );
            $content = "I don't know how to process action '$action_name'.";
            $status = RC_NOT_FOUND;
        }
    };
    if ( $@ ) {
        $log->error( $@ );
        $content = $@;
        $status = RC_INTERNAL_SERVER_ERROR;
    }

    my $cookies_out = $dispatcher->cookie_out_as_objects;

    my $header = $cgi->header( -status => $status,
                               -cookie => $cookies_out );
    $log->is_debug && $log->debug( "Sending header to client:\n=====\n$header\n=====" );
    print $header, $content;
}
