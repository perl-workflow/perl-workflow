package Workflow::Persister::DBI;

# $Id$

use strict;
use base qw( Workflow::Persister );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( configuration_error persist_error );

$Workflow::Persister::DBI::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub init {
}


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

Workflow::Persister::DBI - Persist workflow and history to DBI database

=head1 SYNOPSIS

 <persister name="MainDatabase"
            class="Workflow::Persister::DBI"
            driver="MySQL"
            dsn="DBI:mysql:database=workflows"
            user="wf"
            password="mypass"/>
 
 <persister name="BackupDatabase"
            class="Workflow::Persister::DBI"
            driver="PostgreSQL"
            dsn="DBI:Pg:dbname=workflows"
            user="wf"
            password="mypass"
            workflow_sequence="wf_seq"
            workflow_history_sequence="wf_history_seq"/>
 

=head1 DESCRIPTION

Main persistence class for storing the workflow and workflow history
records to a DBI-accessible datasource.

=head1 OBJECT METHODS

=head1 SEE ALSO

L<Workflow::Persister>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
