package App::Web;

use strict;
use vars qw($VERSION);
use Log::Log4perl     qw( get_logger );
use Workflow::Factory qw( FACTORY );
use XML::Simple       qw( :strict );

$VERSION = '0.01';

my ( $log );

my %ACTION_DATA = ();
my %DISPATCH    = ();

sub initialize_mappings {
    my ( $class, $mapping_file ) = @_;
    $log ||= get_logger();
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
        my $method = \&{ $map_class . '::' . $map_method };
        unless ( $method ) {
            die "No method '$map_class->$map_method'\n";
        }
        $DISPATCH{ $url_map->{url} } = $method;
    }

    foreach my $action_template ( @{ $config->{'action-display'} } ) {
        $ACTION_DATA{ $action_template->{name} } = $action_template->{template};
    }

    return $config;
}


########################################
# DISPATCH MAPPINGS
#
# Each of these routines returns a template name, stuffing data used
# by the template into \%params and any outbound cookies into
# \%cookies_out.

sub lookup_dispatch {
    my ( $class, $action_name ) = @_;
    return $DISPATCH{ $action_name };
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

1;
