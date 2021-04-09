package Workflow::Persister::SPOPS;

use warnings;
use strict;
use base qw( Workflow::Persister );
use DateTime;
use Log::Log4perl qw( get_logger );
use Workflow::Exception qw( configuration_error persist_error );
use English qw( -no_match_vars );

$Workflow::Persister::SPOPS::VERSION = '1.53';

my @FIELDS = qw( workflow_class history_class );
__PACKAGE__->mk_accessors(@FIELDS);

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init($params);
    unless ( $params->{workflow_class} ) {
        configuration_error "SPOPS implementation for persistence must ",
            "specify 'workflow_class' parameter ", "in configuration.";
    }
    $self->workflow_class( $params->{workflow_class} );
    unless ( $params->{history_class} ) {
        configuration_error "SPOPS implementation for persistence must ",
            "specify 'history_class' parameter ", "in configuration.";
    }
    $self->history_class( $params->{history_class} );
}

sub create_workflow {
    my ( $self, $wf ) = @_;
    my $wf_persist = $self->workflow_class->new(
        {   state       => $wf->state,
            type        => $wf->type,
            last_update => DateTime->now( time_zone => $wf->time_zone() ),
        }
    );
    eval { $wf_persist->save };
    if ($EVAL_ERROR) {
        persist_error "Failed to create new workflow: $EVAL_ERROR";
    }
    return $wf_persist->id;
}

sub fetch_workflow {
    my ( $self, $wf_id ) = @_;
    my $wf_persist = eval { $self->workflow_class->fetch($wf_id) };
    if ($EVAL_ERROR) {
        persist_error "Failed to fetch workflow '$wf_id': $EVAL_ERROR";
    }
    return $wf_persist;
}

sub update_workflow {
    my ( $self, $wf ) = @_;
    my $wf_id = $wf->id;
    my $wf_persist = eval { $self->workflow_class->fetch($wf_id) };
    if ($EVAL_ERROR) {
        persist_error
            "Cannot fetch record '$wf_id' for updating: $EVAL_ERROR";
    }
    $wf_persist->state( $wf->state );
    $wf_persist->last_update( $wf->last_update );
    eval { $wf_persist->save };
    if ($EVAL_ERROR) {
        persist_error "Failed to update workflow '$wf_id': $EVAL_ERROR";
    }
    return $wf_persist;
}

sub create_history {
    my ( $self, $wf, @history ) = @_;
    $self->log->debug( "Saving history for workflow ", $wf->id );
    foreach my $h (@history) {
        next if ( $h->is_saved );
        my $hist_persist = eval {
            $self->history_class->new(
                {   workflow_id  => $wf->id,
                    action       => $h->action,
                    description  => $h->description,
                    state        => $h->state,
                    user         => $h->user,
                    history_date => $h->date
                }
            )->save();
        };
        if ($EVAL_ERROR) {
            persist_error "Failed to save history record: $EVAL_ERROR";
        } else {
            $h->id( $hist_persist->id );
            $h->set_saved();
            $self->log->info( "Created history record with ID ",
                $hist_persist->id );
        }
    }
    return @history;
}

sub fetch_history {
    my ( $self, $wf ) = @_;
    my $persist_histories = eval {
        $self->history_class->fetch_group(
            {   where => 'workflow_id = ?',
                value => [ $wf->id ],
                order => 'history_date DESC'
            }
        );
    };
    if ($EVAL_ERROR) {
        persist_error "Error fetching workflow history: $EVAL_ERROR";
    }
    my @histories = ();
    for ( @{$persist_histories} ) {
        my $hist = Workflow::History->new(
            {   id          => $_->id,
                workflow_id => $_->workflow_id,
                action      => $_->action,
                description => $_->description,
                state       => $_->state,
                user        => $_->user,

                # NOTE: SPOPS class must return this as a DateTime object...
                date      => $_->history_date,
                time_zone => $_->time_zone,
            }
        );
        $hist->set_saved();
        push @histories, $hist;
    }
    return @histories;
}

1;

__END__

=pod

=head1 NAME

Workflow::Persister::SPOPS - Persist workflows using SPOPS

=head1 VERSION

This documentation describes version 1.53 of this package

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

=head2 METHODS

=head3 init ( \%params)

This method initializes the SPOPS persistance entity.

It requires that a workflow_class and a history_class are specified. If not the
case L<Workflow::Exception>s are thrown.

=head3 create_workflow

Serializes a workflow into the persistance entity configured by our workflow.

Takes a single parameter: a workflow object

Returns a single value, a id for unique identification of out serialized
workflow for possible deserialization.

=head3 fetch_workflow

Deserializes a workflow from the persistance entity configured by our workflow.

Takes a single parameter: the unique id assigned to our workflow upon
serialization (see L</create_workflow>).

Returns a hashref consisting of two keys:

=over

=item * state, the workflows current state

=item * last_update, date indicating last update

=back

=head3 update_workflow

Updates a serialized workflow in the persistance entity configured by our
workflow.

Takes a single parameter: a workflow object

Returns: Nothing

=head3 create_history

Serializes history records associated with a workflow object

Takes two parameters: a workflow object and an array of workflow history objects

Returns: provided array of workflow history objects upon success

=head3 fetch_history

Deserializes history records associated with a workflow object

Takes a single parameter: a workflow object

Returns an array of workflow history objects upon success

=head1 SEE ALSO

=over

=item * L<Workflow::Persister>

=item * L<SPOPS>

=item * L<SPOPS::Tool::DateConvert>

=back

=head1 COPYRIGHT

Copyright (c) 2003-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
