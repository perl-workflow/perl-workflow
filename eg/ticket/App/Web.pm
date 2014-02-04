package App::Web;

use strict;
use vars qw($VERSION);
use CGI::Cookie;
use Cwd                   qw( cwd );
use Data::Dumper          qw( Dumper );
use File::Spec::Functions qw( catdir );
use Log::Log4perl         qw( get_logger );
use Template;
use Workflow::Factory     qw( FACTORY );
use XML::Simple           qw( :strict );

$VERSION = '0.01';

# Default logfile name; can change with arg to init_logger()
my $DEFAULT_LOG_FILE = 'workflow.log';

my ( $log );

my %ACTION_DATA = ();
my %DISPATCH    = ();

########################################
# DISPATCHER

sub create_dispatcher {
    my ( $class, %params ) = @_;
    $log ||= get_logger();
    $log->is_info && $log->info( "Creating new dispatcher" );
    my $self = bless({
        cgi        => $params{cgi},
        cookie_in  => {},
        cookie_out => {},
        template   => undef }, $class );

    # Note that this creates $self->{params}, so don't assign before
    # this statement

    $self->_assign_args( $params{cgi} );
    $log->is_debug && $log->debug( "Assigned arguments ok" );

    $self->param( base_url => $params{base_url} );

    $self->_create_cookies( $params{cookie_text} );
    $log->is_debug && $log->debug( "Created cookies ok" );

    $self->_init_templating( $params{include_path} );

    return $self;
}

sub _assign_args {
    my ( $self, $cgi ) = @_;
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
    return $self->{params} = \%params;
}

sub _create_cookies {
    my ( $self, $cookie_header ) = @_;
    $log->is_debug &&
        $log->debug( "Got cookie header from client '$cookie_header'" );
    my %cookies_in = CGI::Cookie->parse( $cookie_header );
    foreach my $name ( keys %cookies_in ) {
        my $value = $cookies_in{ $name }->value;
        $self->cookie_in( $name, $value );
        unless ( $self->param( $name ) ) {
            $self->param( $name, $value );
        }
    }
}

sub param {
    my ( $self, $name, $value ) = @_;
    if ( $name and $value ) {
        return $self->{params}{ $name } = $value;
    }
    elsif ( $name ) {
        return $self->{params}{ $name };
    }
    return $self->{params};
}

sub cookie_in {
    my ( $self, $name, $value ) = @_;
    if ( $name and $value ) {
        $log->is_debug &&
            $log->debug( "Adding inbound cookie: '$name' = '$value'" );
        $self->{cookie_in}{ $name } = $value;
    }
    if ( $name ) {
        return $self->{cookie_in}{ $name }
    }
    return $self->{cookie_in};
}

sub cookie_out {
    my ( $self, $name, $value ) = @_;
    if ( $name and $value ) {
        $log->is_debug &&
            $log->debug( "Adding outbound cookie: '$name' = '$value'" );
        $self->{cookie_out}{ $name } = $value;
    }
    if ( $name ) {
        return $self->{cookie_out}{ $name }
    }
    return $self->{cookie_out};
}

sub cookie_out_as_objects {
    my ( $self ) = @_;
    my @values = ();
    my $cookies_out = $self->cookie_out;
    if ( scalar keys %{ $cookies_out } ) {
        while ( my ( $name, $value ) = each %{ $cookies_out } ) {
            my $obj = CGI::Cookie->new( -name  => $name,
                                        -value => $value );
            my $cookie = $obj->as_string;
            push @values, $cookie;
            $log->is_debug && $log->debug( "Outbound cookie found: $cookie" );
        }
    }
    else {
        $log->is_info && $log->info( "No outbound cookies found" );
    }
    return \@values;
}

########################################
# DISPATCH MAPPINGS

sub is_dispatchable {
    my ( $self, $action_name ) = @_;
    return undef unless ( $action_name );
    return defined $DISPATCH{ $action_name };
}

sub run {
    my ( $self, $action_name ) = @_;
    if ( $DISPATCH{ $action_name } ) {
        return $DISPATCH{ $action_name }->( $self );
    }
    else {
        die "No such action '$action_name'\n";
    }
}


# Each of these routines returns a template name

sub _action_create_workflow {
    my ( $self ) = @_;
    my $wf = FACTORY->create_workflow( 'Ticket' );
    $self->param( workflow => $wf );
    $self->cookie_out( workflow_id => $wf->id );
    return 'workflow_created.tmpl';
}

sub _action_fetch_workflow {
    my ( $self ) = @_;
    my $wf = $self->_get_workflow();
    $self->cookie_out( workflow_id => $wf->id );
    return 'workflow_fetched.tmpl';
}

sub _action_list_history {
    my ( $self ) = @_;
    my $wf = $self->_get_workflow();
    my @history = $wf->get_history();
    $self->param( history_list => \@history );
    return 'workflow_history.tmpl';
}

sub _action_execute_action {
    my ( $self ) = @_;
    my $wf = $self->_get_workflow();

    my $action = $self->param( 'action' );
    unless ( $action ) {
        die "To execute an action you must specify an action name!\n";
    }

    # If they haven't entered data yet, add the fields (as a map) to
    # the parameters and redirect to the form for entering it

    unless ( $self->param( '_action_data_entered' ) || ! $ACTION_DATA{ $action } ) {
        $self->param( status_msg =>
                      'Action cannot be executed until you enter its data' );
        my @fields = $wf->get_action_fields( $action );
        my %by_name = map { $_->name => $_ } @fields;
        $self->param( ACTION_FIELDS => \%by_name );
        return $ACTION_DATA{ $action };
    }

    # Otherwise, set the user data directly into the workflow context...
    $wf->context->param( $self->param );

    # ...and execute the action
    eval { $wf->execute_action( $self->param( 'action' ) ) };

    # ...if we catch a condition/validation exception, display the
    # error and go back to the data entry form

    if ( $@ && ( $@->isa( 'Workflow::Exception::Condition' ) ||
                 $@->isa( 'Workflow::Exception::Validation' ) ) ) {
        $log->error( "One or more conditions not met to execute action: $@; ",
                     "redirecting to form" );
        $self->param( error_msg => "Failed to execute action: $@" );
        return $ACTION_DATA{ $action };
    }
    $self->param( status_msg => "Action '$action' executed ok" );
    return $self->_action_list_history();
}

sub _action_login {
    my ( $self ) = @_;
    if ( my $user = $self->param( 'current_user' ) ) {
        $self->cookie_out( current_user => $user );
    }
    else {
        $self->param( error_msg => "Please specify a login name I can use!" );
    }
    return 'index.tmpl';
}

sub _get_workflow {
    my ( $self ) = @_;
    return $self->param( 'workflow' )  if ( $self->param( 'workflow' ) );
    my $log = get_logger();
    my $wf_id = $self->param( 'workflow_id' ) || $self->cookie_in( 'workflow_id' );
    unless ( $wf_id ) {
        die "No workflow ID given! Please fetch a workflow or create ",
            "a new one.\n";
    }
    $log->is_debug &&
        $log->debug( "Fetching workflow with ID '$wf_id'" );
    my $wf = FACTORY->fetch_workflow( 'Ticket', $wf_id );
    if ( $wf ) {
        $log->is_debug &&
            $log->debug( "Workflow found; current state: '", $wf->state, "'" );
        $self->param( workflow => $wf );
    }
    else {
        my $msg = "No workflow found with ID '$wf_id'";
        $log->warn( $msg );
        die "$msg\n";
    }
    $log->is_info &&
        $log->info( "Setting current user to: ", $self->cookie_in( 'current_user' ) );
    $wf->context->param( current_user => $self->cookie_in( 'current_user' ) );
    if ( my $ticket_id = $wf->context->param( 'ticket_id' ) ) {
        my $ticket = App::Ticket->fetch( $ticket_id );
        $log->info( "Adding ticket [ID: ", $ticket->id, "] to context" );
        $wf->context->param( ticket => $ticket );
    }
    return $wf;
}

########################################
# TEMPLATE PROCESSING

sub process_template {
    my ( $self, $template_name ) = @_;
    $log->is_debug &&
        $log->debug( "Processing template '$template_name'..." );
    my ( $content );
    my $t = $self->{template};
    my %template_params = (
        dispatcher => $self,
        cgi        => $self->{cgi},
        %{ $self->param },
    );
#    local $Data::Dumper::Indent = 1;
#    $log->is_debug &&
#        $log->debug( "Sending the following parameters: ", Dumper( \%template_params ) );
    $t->process( $template_name, \%template_params, \$content )
        || die "Cannot process template '$template_name': ", $t->error, "\n";
    $log->is_debug &&
        $log->debug( "Processed template ok" );
    return $content;
}

sub _init_templating {
    my ( $self, $include_path ) = @_;
    unless ( $include_path ) {
        $include_path = catdir( cwd(), 'web_templates' );
    }
    $log->is_info &&
        $log->info( "Initializing the template object with path: $include_path" );
    my $template = Template->new( INCLUDE_PATH => $include_path );
    $log->is_info &&
        $log->info( "Finished initializing the template object" );
    return $self->{template} = $template;
}



########################################
# INITIALIZATION

sub init_logger {
    my ( $log_file ) = @_;
    $log_file ||= $DEFAULT_LOG_FILE;
    if ( -f $log_file ) {
        my $log_mod_time = (stat $log_file)[9];
        if ( time - $log_mod_time > 600 ) { # 10 minutes
            unlink( $log_file );
        }
    }
    Log::Log4perl::init( 'log4perl.conf' );
    $log = get_logger();
}

sub init_factory {
    $log->is_info &&
        $log->info( "Starting to configure workflow factory" );

    $log->warn( "Will use parser of class: ", Workflow::Config->get_factory_class( 'xml' ) );

    FACTORY->add_config_from_file(
        workflow  => 'workflow.xml',
        action    => 'workflow_action.xml',
        validator => 'workflow_validator.xml',
        condition => 'workflow_condition.xml',
        persister => 'workflow_persister.xml'
    );
    $log->is_info &&
        $log->info( "Finished configuring workflow factory" );
}

sub init_url_mappings {
    my ( $class, $mapping_file ) = @_;
    $log->is_info &&
        $log->info( "Initializing the URL and action mappings" );
    my %options = (
        ForceArray => [ 'url-mapping', 'action-display' ],
        KeyAttr    => [],
    );
    my $config = XMLin( $mapping_file, %options );
    no strict 'refs';
    foreach my $url_map ( @{ $config->{'url-mapping'} } ) {
        my $map_class  = $url_map->{class};
        my $map_method = $url_map->{method};
        eval "require $map_class";
        if ( $@ ) {
            die "Cannot include class '$map_class': $@\n";
        }

        # All dispatch methods begin with '_action_'
        my $method = \&{ $map_class . '::_action_' . $map_method };
        unless ( $method ) {
            die "No method '$map_class->$map_method'\n";
        }
        $DISPATCH{ $url_map->{url} } = $method;
    }

    foreach my $action_template ( @{ $config->{'action-display'} } ) {
        $ACTION_DATA{ $action_template->{name} } = $action_template->{template};
    }

    $log->is_info &&
        $log->info( "Finished initializing the URL and action mappings" );
    return $config;
}

# DEPRECATED

sub lookup_dispatch {
    my ( $self, $action_name ) = @_;
    warn "Method 'lookup_dispatch()' is deprecated; just use 'run()' to ",
         "actually dispatch the action\n";
    return $DISPATCH{ $action_name };
}

1;
