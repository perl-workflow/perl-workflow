package Workflow::Persister::SPOPS;

# $Id$

use strict;
use base qw( Workflow::Persister );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( configuration_error persist_error );

$Workflow::Persister::SPOPS::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( workflow_class history_class );
__PACKAGE__->mk_accessors( @FIELDS );

sub init {
    my ( $self, $params ) = @_;
    unless ( $params->{workflow_class} ) {
        configuration_error "SPOPS implementation for persistence must ",
                            "specify 'workflow_class' parameter ",
                            "in configuration.";
    }
    $self->workflow_class( $params->{workflow_class} );
}

sub fetch_workflow {
    my ( $self, $wf_id ) = @_;
    my $wf_persist = eval { $self->workflow_class->fetch( $wf_id ) };
    if ( $@ ) {
        persist_error "Failed to fetch workflow '$wf_id': $@";
    }
    return $wf_persist;
}

sub create_workflow {
    my ( $self, $wf ) = @_;
    my $wf_persist = $self->workflow_class->new({ state => $wf->state });
    eval { $wf_persist->save };
    if ( $@ ) {
        persist_error "Failed to create new workflow: $@";
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
    eval { $wf_persist->save };
    if ( $@ ) {
        persist_error "Failed to update workflow '$wf_id': $@";
    }
    return $wf_persist;
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

Workflow::Persister::SPOPS - Persist workflows using SPOPS

=head1 SYNOPSIS

 <workflow type="foo">
   <persister class="Workflow::Persister::SPOPS"
              workflow_class="WorkflowPersist"
              history_class="WorkflowHistoryPersist"/>

=head1 DESCRIPTION

=head1 CLASS METHODS

=head1 OBJECT METHODS

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
