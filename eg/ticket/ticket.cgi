#!/usr/bin/perl

use strict;
use App::Web;
use CGI;
use HTTP::Status;
use Log::Log4perl qw( get_logger );

App::Web->init_logger();
App::Web->init_factory();
App::Web->init_url_mappings( 'web_workflow.xml' );

my $template = App::Web->init_templating();
my $log = get_logger();

{
    my $cgi = CGI->new();
    my $cookie_text = $cgi->raw_cookie;
    my $dispatcher = App::Web->create_dispatcher(
        cgi         => $cgi,
        cookie_text => $cookie_text
    );
    my ( $action_name ) = $cgi->path_info =~ m|^/(\w+)/|;

    # default status
    my $status = RC_OK;

    # page content goes here
    my ( $content );

    # hold the template to process here
    my ( $template_name );

    $log->is_info &&
        $log->info( "Trying to dispatch action '$action_name'" );

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
        $log->debug( "Processing template '$template_name'..." );
        eval {
            $template->process( $template_name, $dispatcher->param, \$content )
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
    elsif ( ! $action_name ) {
        $log->debug( "Processing index template since no action given" );
        $template->process( 'index.tmpl', {}, \$content );
    }
    else {
        $log->error( "No dispatch found for action '$action_name'" );
        $content = "I don't know how to process action '$action_name'.";
        $status = RC_NOT_FOUND;
    }

    print $cgi->header( -status => $status,
                        -cookie => $dispatcher->cookie_out_as_objects ),
          $content;
}
