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

# First initialize the factory...

FACTORY->add_config_from_file( workflow  => 'workflow.xml',
                               action    => 'workflow_action.xml',
                               validator => 'workflow_validator.xml',
                               condition => 'workflow_condition.xml',
                               persister => 'workflow_persister.xml' );
$log->info( "Finished configuring workflow factory" );

# Next read in the URL-to-code and action-to-template mappings

$log->info( "Initializing the URL and action mappings" );
App::Web->initialize_mappings( 'web_workflow.xml' );
$log->info( "Finished initializing the URL and action mappings" );

# Then initialize the template object

$log->info( "Initializing the template object" );
my $template = Template->new( INCLUDE_PATH => catdir( cwd(), 'web_templates' ) );
$log->info( "Finished initializing the template object" );

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

    if ( my $action_sub = App::Web->lookup_dispatch( $action ) ) {
        $log->debug( "Dispatch method found for '$action', executing..." );
        my $template_name = eval {
            $action_sub->( $client, $request, \%cookies_in, \%cookies_out, \%params )
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
