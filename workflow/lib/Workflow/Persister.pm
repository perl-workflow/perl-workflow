package Workflow::Persister;

# $Id$

use strict;
use base qw( Workflow::Base );
use Workflow::Exception qw( persist_error );

$Workflow::Persister::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

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



=head1 SEE ALSO

L<Workflow::Factory>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
