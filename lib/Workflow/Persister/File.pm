package Workflow::Persister::File;

# $Id$

use strict;
use base qw( Workflow::Persister );
use Data::Dumper          qw( Dumper );
use File::Spec::Functions qw( catdir catfile );
use Log::Log4perl         qw( get_logger );
use Workflow::Exception   qw( configuration_error persist_error );
use Workflow::Persister::RandomId;

$Workflow::Persister::File::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( path );
__PACKAGE__->mk_accessors( @FIELDS );

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init( $params );
    my $log = get_logger();
    unless ( $self->use_uuid eq 'yes' || $self->use_random eq 'yes' ) {
        $self->use_random( 'yes' );
    }
    $self->assign_generators( $params );
    unless ( $params->{path} ) {
        configuration_error "The file persister must have the 'path' ",
                            "specified in the configuration";
    }
    unless ( -d $params->{path} ) {
        configuration_error "The file persister must have a valid directory ",
                            "specified in the 'path' key of the configuration ",
                            "(given: '$params->{path}')";
    }
    $log->is_info &&
        $log->info( "Using path for workflows and histories '$params->{path}'" );
    $self->path( $params->{path} );
}

sub create_workflow {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    my $generator = $self->workflow_id_generator;
    my $wf_id = $generator->pre_fetch_id();
    $wf->id( $wf_id );
    $log->is_debug &&
        $log->debug( "Generated workflow ID '$wf_id'" );
    $self->_serialize_workflow( $wf );
    my $full_history_path = $self->_get_history_path( $wf );
    mkdir( $full_history_path, 0777 )
        || persist_error "Cannot create history dir '$full_history_path': $!";
    return $wf_id;
}

sub fetch_workflow {
    my ( $self, $wf_id ) = @_;
    my $log = get_logger();
    my $full_path = $self->_get_workflow_path( $wf_id );
    $log->is_debug &&
        $log->debug( "Checking to see if workflow exists in '$full_path'" );
    unless ( -f $full_path ) {
        $log->error( "No file at path '$full_path'" );
        persist_error "No workflow with ID '$wf_id' is available";
    }
    $log->is_debug &&
        $log->debug( "File exists, reconstituting workflow" );
    my $wf_info = eval { $self->constitute_object( $full_path ) };
    if ( $@ ) {
        persist_error "Cannot reconstitute data from file for ",
                      "workflow '$wf_id': $@";
    }
    return $wf_info;
}

sub update_workflow {
    my ( $self, $wf ) = @_;
    $self->_serialize_workflow( $wf );
}

sub create_history {
    my ( $self, $wf, @history ) = @_;
    my $generator = $self->history_id_generator;
    my $log = get_logger();
    my $history_dir = $self->_get_history_path( $wf );
    $log->is_info &&
        $log->info( "Will use directory '$history_dir' for history" );
    foreach my $history ( @history ) {
        if ( $history->is_saved ) {
            $log->is_debug &&
                $log->debug( "History object saved, skipping..." );
            next;
        }
        $log->is_debug &&
            $log->debug( "History object unsaved, continuing..." );
        my $history_id = $generator->pre_fetch_id();
        $history->id( $history_id );
        my $history_file = catfile( $history_dir, $history_id );
        $self->serialize_object( $history_file, $history );
        $log->is_info &&
            $log->info( "Created history object '$history_id' ok" );
        $history->set_saved();
    }
}

sub fetch_history {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    my $history_dir = $self->_get_history_path( $wf );
    $log->is_debug &&
        $log->debug( "Trying to read history files from dir '$history_dir'" );
    opendir( HISTORY, $history_dir )
        || persist_error "Cannot read history from '$history_dir': $!";
    my @history_files = grep { -f $_ } 
                        map { catfile( $history_dir, $_ ) }
                        readdir( HISTORY );
    closedir( HISTORY );
    my @histories = ();
    foreach my $history_file ( @history_files ) {
        $log->is_debug &&
            $log->debug( "Reading history from file '$history_file'" );
        my $history = $self->constitute_object( $history_file );
        $history->set_saved();
        push @histories, $history;
    }
    return @histories;
}

sub _serialize_workflow {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    local $Data::Dumper::Indent = 1;
    my $full_path = $self->_get_workflow_path( $wf->id );
    $log->is_debug &&
        $log->debug( "Trying to write workflow to '$full_path'" );
    my %wf_info = (
        id          => $wf->id,
        state       => $wf->state,
        last_update => $wf->last_update,
        type        => $wf->type,
    );
    $self->serialize_object( $full_path, \%wf_info );
    $log->is_debug &&
        $log->debug( "Wrote workflow ok" );
}

sub serialize_object {
    my ( $self, $path, $object ) = @_;
    my $log = get_logger();
    $log->is_info &&
        $log->info( "Trying to save object of type '", ref( $object ), "' ",
                    "to path '$path'" );
    open( THINGY, '>', $path )
        || persist_error "Cannot write to '$path': $!";
    print THINGY Dumper( $object );
    close( THINGY );
    $log->is_debug &&
        $log->debug( "Wrote object to file ok" );
}

sub constitute_object {
    my ( $self, $object_path ) = @_;
    open( IN, '<', $object_path );
    my $content = join( '', <IN> );
    close( IN );
    no strict;
    my $object = eval $content;
    die $@ if ( $@ );
    return $object;

}

sub _get_workflow_path {
    my ( $self, $wf_id ) = @_;
    my $log = get_logger();
    $log->is_info &&
        $log->info( "Creating workflow file from '", $self->path, "' ",
                    "and ID '$wf_id'" );
    return catfile( $self->path, $wf_id . '_workflow' );
}

sub _get_history_path {
    my ( $self, $wf ) = @_;
    return catdir( $self->path, $wf->id . '_history' );
}

1;

__END__

=head1 NAME

Workflow::Persister::File - Persist workflow and history to the filesystem

=head1 SYNOPSIS

 <persister name="MainPersister"
            class="Workflow::Persister::File"
            path="/home/workflow/storage"/>

=head1 DESCRIPTION

Main persistence class for storing the workflow and workflow history
records to a filesystem for later retrieval.

=head1 OBJECT METHODS

=head1 SEE ALSO

L<Workflow::Persister>

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
