package Workflow::Persister::File;

# $Id$

use strict;
use base qw( Workflow::Persister );
use Data::Dumper        qw( Dumper );
use File::Spec::Functions;
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( configuration_error persist_error );
use Workflow::Persister::RandomId;

$Workflow::Persister::File::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( path );
__PACKAGE__->mk_accessors( @FIELDS );

sub init {
    my ( $self, $params ) = @_;
    my $generator = Workflow::Persister::RandomId->new({ id_length => 8 });
    unless ( $params->{path} ) {
        configuration_error "The file persister must have the 'path' ",
                            "specified in the configuration";
    }
    unless ( -d $params->{path} ) {
        configuration_error "The file persister must have a valid directory ",
                            "specified in the 'path' key of the configuration ",
                            "(given: '$params->{path}')";
    }
    $self->path( $params->{path} );
}

sub create_workflow {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    my $wf_id = $generator->pre_fetch_id();
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
    $log->debug( "Checking to see if workflow at '$full_path'" );
    unless ( -f $full_path ) {
        $log->error( "No file at path '$full_path'" );
        persist_error "No workflow with ID '$wf_id' is available";
    }
    my $wf_info = eval { $self->_constitute_object( $full_path ) };
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
    my $log = get_logger();
    my $history_dir = $self->_get_history_path( $wf );
    foreach my $history ( $wf->get_history ) {
        next if ( $history->is_saved );
        my $history_id = $generator->pre_fetch_id();
        $history->id( $history_id );
        my $history_file = catfile( $history_dir, $history_id );
        $self->_serialize_object( $history_file, $history );
        $log->info( "Created history object '$history_id' ok" );
    }
}

sub fetch_history {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    my $history_dir = $self->_get_history_path( $wf );
    opendir( HISTORY, $history_dir )
        || persist_error "Cannot read history from '$history_dir': $!";
    my @history_files = grep { -f $_ } readdir( HISTORY );
    closedir( HISTORY );
    my @histories = ();
    foreach my $history_file ( @history_files ) {
        my $full_history_file = catfile( $history_dir, $history_file );
        my $history = $self->_constitute_object( $full_history_file );
        push @histories, $history;
    }
    return @histories;
}

sub _serialize_workflow {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    local $Data::Dumper::Indent = 1;
    my $full_path = $self->_get_workflow_path( $wf->id );
    $log->debug( "Trying to write workflow to '$full_path'" );
    my %wf_info = (
        id    => $wf->id,
        state => $wf->state,
    );
    $self->_serialize_object( $full_path, \%wf_info );
    $log->debug( "Wrote workflow ok" );
}

sub _serialize_object {
    my ( $self, $path, $object ) = @_
    open( THINGY, '>', $path )
        || persist_error "Cannot write to '$path': $!";
    print THINGY Dumper( $wf );
    close( THINGY );
}

sub _constitute_object {
    my ( $self, $object_path ) = @_;
    open( IN, '<', $object_path );
    my $content = join( '', <IN> );
    close( IN );
    no strict 'refs';
    my $object = eval $content;
    die $@ if ( $@ );
    return $object;

}

sub _get_workflow_path {
    my ( $self, $wf_id ) = @_;
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

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
