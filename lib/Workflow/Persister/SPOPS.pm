package Workflow::Persister::SPOPS;

# $Id$

use strict;
use base qw( Workflow::Persister );
use DateTime;
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( configuration_error persist_error );

$Workflow::Persister::SPOPS::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( workflow_class history_class );
__PACKAGE__->mk_accessors( @FIELDS );

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init( $params );
    unless ( $params->{workflow_class} ) {
        configuration_error "SPOPS implementation for persistence must ",
                            "specify 'workflow_class' parameter ",
                            "in configuration.";
    }
    $self->workflow_class( $params->{workflow_class} );
    unless ( $params->{history_class} ) {
        configuration_error "SPOPS implementation for persistence must ",
                            "specify 'history_class' parameter ",
                            "in configuration."
    }
    $self->history_class( $params->{history_class} );
}

sub create_workflow {
    my ( $self, $wf ) = @_;
    my $wf_persist = $self->workflow_class->new({
        state       => $wf->state,
        type        => $wf->type,
        last_update => DateTime->now,
    });
    eval { $wf_persist->save };
    if ( $@ ) {
        persist_error "Failed to create new workflow: $@";
    }
    return $wf_persist->id;
}

sub fetch_workflow {
    my ( $self, $wf_id ) = @_;
    my $wf_persist = eval {
        $self->workflow_class->fetch( $wf_id )
    };
    if ( $@ ) {
        persist_error "Failed to fetch workflow '$wf_id': $@";
    }
    return $wf_persist;
}

sub update_workflow {
    my ( $self, $wf ) = @_;
    my $wf_id = $wf->id;
    my $wf_persist = eval { $self->workflow_class->fetch( $wf_id ) };
    if ( $@ ) {
        persist_error "Cannot fetch record '$wf_id' for updating: $@";
    }
    $wf_persist->state( $wf->state );
    $wf_persist->last_update( $wf->last_update );
    eval { $wf_persist->save };
    if ( $@ ) {
        persist_error "Failed to update workflow '$wf_id': $@";
    }
    return $wf_persist;
}

sub create_history {
    my ( $self, $wf, @history ) = @_;
    my $log = get_logger();
    $log->debug( "Saving history for workflow ", $wf->id );
    foreach my $h ( @history ) {
        next if ( $h->is_saved );
        my $hist_persist = eval {
            $self->history_class->new({
                workflow_id  => $wf->id,
                action       => $h->action,
                description  => $h->description,
                state        => $h->state,
                user         => $h->user,
                history_date => $h->date
            })->save();
        };
        if ( $@ ) {
            persist_error "Failed to save history record: $@";
        }
        else {
            $h->id( $hist_persist->id );
            $h->set_saved();
            $log->info( "Created history record with ID ", $hist_persist->id );
        }
    }
    return @history;
}

sub fetch_history {
    my ( $self, $wf ) = @_;
    my $persist_histories = eval {
        $self->history_class->fetch_group({ where => 'workflow_id = ?',
                                            value => [ $wf->id ],
                                            order => 'history_date DESC' });
    };
    if ( $@ ) {
        persist_error "Error fetching workflow history: $@";
    }
    my @histories = ();
    for ( @{ $persist_histories } ) {
        my $hist = Workflow::History->new({
            id           => $_->id,
            workflow_id  => $_->workflow_id,
            action       => $_->action,
            description  => $_->description,
            state        => $_->state,
            user         => $_->user,
# NOTE: SPOPS class must return this as a DateTime object...
            date         => $_->history_date,
        });
        $hist->set_saved();
        push @histories, $hist;
    }
    return @histories;
}

1;

__END__

=head1 NAME

Workflow::Persister::SPOPS - Persist workflows using SPOPS

=head1 SYNOPSIS

 <persister name="SPOPSPersister"
            class="Workflow::Persister::SPOPS"
            workflow_class="My::Persist::Workflow"
            history_class="My::Persist::History"/>

=head1 DESCRIPTION

=head2 Overview

Use a SPOPS classes to persist your workflow and workflow history
information. Configuration is simple: just specify the class names and
everything else is done.

We do not perform any class initialization, so somewhere in your
server/process startup code you should have something like:

 my $config = get_workflow_and_history_config();
 SPOPS::Initialize->process({ config => $config });

This will generate the classes named in the persister configuration.

=head2 SPOPS Configuration

B<NOTE>: The configuration for your workflow history object B<must>
use the L<SPOPS::Tool::DateConvert> to translate the 'history_date'
field into a L<DateTime> object. We assume when we fetch the history
object that this has already been done.

=head1 SEE ALSO

L<Workflow::Persister>

L<SPOPS>

L<SPOPS::Tool::DateConvert>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
