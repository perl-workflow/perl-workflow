package Workflow::Persister::DBI::ExtraData;

# $Id$

use strict;
use base qw( Workflow::Persister::DBI );
use Workflow::Exception qw( configuration_error persist_error );

$Workflow::Persister::DBI::ExtraData::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( table data_field context_key );

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init( $params );

    # now configure additional info...
    foreach my $field ( @FIELDS ) {
        my $param_name = "extra_$field";
        if ( $params->{ $param_name } ) {
            $self->$field( $params->{ $param_name } );
        }
        else {
            push @not_found, $required_field;
        }
    }

    if ( scalar @not_found ) {
        configuration_error
            "To fetch extra data with each workflow with this implementation ",
            "you must specify: ", join( ', ', @not_found );
    }

}

sub fetch_extra_workflow_data {
    my ( $self, $wf ) = @_;
    my $log = get_logger();

    $log->debug( "Fetching extra workflow data for '", $wf->id, "'" );

    my $sql = q{
       SELECT %s FROM %s
        WHERE workflow_id = ?
    };
    $sql = sprintf( $sql, $self->data_field, $self->table );
    $log->debug( "Preparing SQL\n$sql" );
    $log->debug( "Binding parameters: ", $wf->id );

    my ( $sth );
    eval {
        $sth = $self->handle->prepare( $sql );
        $sth->execute( $wf->id );
    };
    if ( $@ ) {
        persist_error "Failed to retrieve extra data from table ",
                      $self->table, ": $@" );
    }
    else {
        $log->debug( "Prepared/executed extra data fetch ok" );
        my $row = $sth->fetchrow_arrayref;
        my $value = $row->[0];
        $wf->context->param( $self->context_key, $value );
        $log->info( sprintf( "Set data from %s.%s into context key %s ok",¯
                             $self->table, $self->data_field, $self->context_key ) );
    }
}


1;

__END__

=head1 NAME

Workflow::Persister::DBI::ExtraData - Fetch extra data with each workflow and put it into the context

=head1 SYNOPSIS

 <persister name="MyPersister"
            class="Workflow::Persister::DBI::ExtraData"
            dsn="DBI:mysql:database=workflows"
            user="wf"
            password="mypass"
            extra_table="workflow_ticket"
            extra_data_field="ticket_id"
            extra_context_key="ticket_id"/>

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
