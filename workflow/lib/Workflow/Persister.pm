package Workflow::Persister;

# $Id$

use strict;
use base qw( Workflow::Base );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( persist_error );

$Workflow::Persister::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( name class
                 use_random use_uuid
                 workflow_id_generator history_id_generator );
__PACKAGE__->mk_accessors( @FIELDS );

sub init {
    my ( $self, $params ) = @_;
    my $log = get_logger();
    for ( @FIELDS ) {
        $self->$_( $params->{ $_ } ) if ( $params->{ $_ } );
    }
    unless ( $self->use_random ) {
        $self->use_random( 'no' );
    }
    unless ( $self->use_uuid ) {
        $self->use_uuid( 'no' );
    }
    $log->info( "Initializing persister '", $self->name, "'" );
}

########################################
# COMMON GENERATOR ASSIGNMENTS

sub assign_generators {
    my ( $self, $params ) = @_;
    $params ||= {};

    my $log = get_logger();

    my ( $wf_gen, $history_gen );
    if ( $self->use_uuid eq 'yes' ) {
        $log->debug( "Assigning UUID generators by request" );
        ( $wf_gen, $history_gen ) =
            $self->init_uuid_generators( $params );
    }
    elsif ( $self->use_random eq 'yes' ) {
        $log->debug( "Assigning random ID generators by request" );
        ( $wf_gen, $history_gen ) =
            $self->init_random_generators( $params );
    }
    if ( $wf_gen and $history_gen ) {
        $self->workflow_id_generator( $wf_gen );
        $self->history_id_generator( $history_gen );
    }
}

sub init_random_generators {
    my ( $self, $params ) = @_;
    my $length = $params->{id_length} || 8;
    my $generator =
        Workflow::Persister::RandomId->new({ id_length => $length });
    return ( $generator, $generator );
}

sub init_uuid_generators {
    my ( $self, $params ) = @_;
    my $generator = Workflow::Persister::UUID->new();
    return ( $generator, $generator );
}

########################################
# INTERFACE METHODS

sub create_workflow {
    my ( $self, $wf ) = @_;
    persist_error "Persister '", ref( $self ), "' must implement ",
                  "'create_workflow()'";
}

sub update_workflow {
    my ( $self, $wf ) = @_;
    persist_error "Persister '", ref( $self ), "' must implement ",
                  "'update_workflow()'";
}

sub fetch_workflow {
    my ( $self, $wf_id ) = @_;
    persist_error "Persister '", ref( $self ), "' must implement ",
                  "'fetch_workflow()'";
}

# This is the only one that isn't required...
sub fetch_extra_workflow_data {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    $log->info( "Called empty 'fetch_extra_workflow_data()' (ok)" );
    $log->debug( "An empty implementation is not an error as you may ",
                 "not need this extra functionality. If you do you ",
                 "should use a perister for this purpose (e.g., ",
                 "Workflow::Persister::DBI::ExtraData) or ",
                 "create your own and just implement this method." );
    return;
}

sub create_history {
    my ( $self, $wf, @history ) = @_;
    persist_error "Persister '", ref( $self ), "' must implement ",
                  "'create_history()'";
}

sub fetch_history {
    my ( $self, $wf ) = @_;
    persist_error "Persister '", ref( $self ), "' must implement ",
                  "'fetch_history()'";
}

1;

__END__

=head1 NAME

Workflow::Persister - Base class for workflow persistence

=head1 SYNOPSIS

 # Associate a workflow with a persister
 <workflow type="Ticket"
           persister="MainDatabase">
 ...
 
 # Declare a persister
 <persister name="MainDatabase"
            class="Workflow::Persister::DBI"
            driver="MySQL"
            dsn="DBI:mysql:database=workflows"
            user="wf"
            password="mypass"/>
 
 # Declare a separate persister
 <persister name="FileSystem"
            class="Workflow::Persister::File"
            path="/path/to/my/workflow"/>

=head1 DESCRIPTION

This is the base class for persisting workflows. It does not implement
anything itself but actual implementations should subclass it to
ensure they fulfill the contract.

The job of a persister is to create, update and fetch the workflow
object plus any data associated with the workflow. It also creates and
fetches workflow history records.

=head1 SUBCLASSING

=head2 Strategy

=head2 Methods

B<create_workflow( $workflow )>

Generate an ID for the workflow, serialize the workflow data (ID and
state) and set the ID in the workflow.

B<update_workflow( $workflow )>

Update the workflow state.

B<fetch_workflow( $workflow_id )>

Retrieve the workflow data corresponding to C<$workflow_id>. It not
found return undef, if found return a hashref with the data.

B<create_history( $workflow, @history )>

Serialize all objects in C<@history> for later retrieval.

B<fetch_history( $workflow )>

Return list of L<Workflow::History> objects.

=head1 SEE ALSO

L<Workflow::Factory>

L<Workflow::History>

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
