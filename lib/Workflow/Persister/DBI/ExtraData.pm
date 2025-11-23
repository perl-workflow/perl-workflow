package Workflow::Persister::DBI::ExtraData;

use warnings;
use strict;
use v5.14.0;
use parent qw( Workflow::Persister::DBI );
use Workflow::Exception qw( configuration_error persist_error );
use Syntax::Keyword::Try;

$Workflow::Persister::DBI::ExtraData::VERSION = '2.09';

my @FIELDS = qw( table data_field context_key );
__PACKAGE__->mk_accessors(@FIELDS);

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init($params);

    my @not_found = ();
    foreach (qw( table data_field )) {
        push @not_found, $_ unless ( $params->{"extra_$_"} );
    }
    if ( scalar @not_found ) {
        $self->log->error( "Required configuration fields not found: ",
            join ', ', @not_found );
        configuration_error
            "To fetch extra data with each workflow with this implementation ",
            "you must specify: ", join ', ', @not_found;
    }

    $self->table( $params->{extra_table} );
    my $data_field = $params->{extra_data_field};

    # If multiple data fields specified we don't allow the user to
    # specify a context key

    if ( $data_field =~ /,/ ) {
        $self->data_field( [ split /\s*,\s*/, $data_field ] );
    } else {
        $self->data_field($data_field);
        my $context_key = $params->{extra_context_key} || $data_field;
        $self->context_key($context_key);
    }
    $self->log->info( "Configured extra data fetch with: ",
                      join( '; ', $self->table, $data_field,
                            ( defined $self->context_key
                              ? $self->context_key : '' ) ) );
}

sub fetch_workflow {
    my ( $self, $wf_id ) = @_;
    my $wf_info = $self->SUPER::fetch_workflow( $wf_id );
    my $context = ($wf_info->{context} //= {});

    $self->log->debug( "Fetching extra workflow data for '", $wf_id, "'" );

    my $sql = q{SELECT %s FROM %s WHERE workflow_id = ?};
    my $data_field = $self->data_field;
    my $select_data_fields
        = ( ref $data_field )
        ? join( ', ',
                map { $self->handle->quote_identifier($_) } @{$data_field} )
        : $self->handle->quote_identifier($data_field);
    $sql = sprintf $sql, $select_data_fields,
        $self->handle->quote_identifier( $self->table );
    $self->log->debug( "Using SQL: ", $sql);
    $self->log->debug( "Bind parameters: ", $wf_id );

    my ($sth);
    try {
        $sth = $self->handle->prepare($sql);
        $sth->execute( $wf_id );
    }
    catch ($error) {
        persist_error "Failed to retrieve extra data from table ",
            $self->table, ": $error";
    }

    $self->log->debug("Prepared/executed extra data fetch ok");
    my $row = $sth->fetchrow_arrayref;
    if ( ref $data_field ) {
        foreach my $i ( 0 .. $#{$data_field} ) {
            $context->{$data_field->[$i]} = $row->[$i];
            $self->log->info(
                sprintf( "Set data from %s.%s into context key %s ok",
                         $self->table, $data_field->[$i],
                         $data_field->[$i] ) );
        }
    } else {
        my $value = $row->[0];
        $context->{ $self->context_key } = $value;
        $self->log->info(
            sprintf( "Set data from %s.%s into context key %s ok",
                     $self->table, $self->data_field,
                     $self->context_key ) );
    }

    return $wf_info;
}

1;

__END__

=pod

=head1 NAME

Workflow::Persister::DBI::ExtraData - Fetch extra data with each workflow and put it into the context

=head1 VERSION

This documentation describes version 2.09 of this package

=head1 SYNOPSIS

 persister:
 - name: MyPersister
   class: Workflow::Persister::DBI::ExtraData
   dsn: DBI:mysql:database=workflows
   user: wf
   password: mypass
   extra_table: workflow_ticket
   extra_data_field: ticket_id
   extra_data_context_key: ticket_id

=head1 DESCRIPTION

=head2 Overview

Simple subclass of L<Workflow::Persister::DBI> to allow you to declare
an extra table and data field(s) from which to fetch data whenever you
fetch a workflow. There is a simple restriction: the table must have a
field 'workflow_id' of the same datatype as the 'workflow_id' field in
the 'workflow' table.

=head2 Examples

 # Specify a single field 'ticket_id' from the table 'workflow_ticket'
 # and store it in the context using the same key:

 persister:
 - name: ...
   extra_table: workflow_ticket
   extra_data_field: ticket_id
   ...

 # How you would use this:
 my $wf = FACTORY->fetch_workflow( 'Ticket', 55 );
 print "Workflow is associated with ticket: ",
       $wf->context->param( 'ticket_id' );

 # Specify a single field 'ticket_id' from the table 'workflow_ticket'
 # and store it in the context using a different key

 persister:
 - name: ...
   extra_table: workflow_ticket
   extra_data_field: ticket_id
   extra_context_key: THE_TICKET_ID
   ...

 # How you would use this:
 my $wf = FACTORY->fetch_workflow( 'Ticket', 55 );
 print "Workflow is associated with ticket: ",
       $wf->context->param( 'THE_TICKET_ID' );

 # Specify multiple fields ('ticket_id', 'last_viewer',
 # 'last_view_date') to pull from the 'workflow_ticket' table:

 persister:
 - name: ...
   extra_table: workflow_ticket
   extra_data_field: ticket_id,last_viewer,last_view_date
   ...

 # How you would use this:
 my $wf = FACTORY->fetch_workflow( 'Ticket', 55 );
 print "Workflow is associated with ticket: ",
       $wf->context->param( 'ticket_id' ), " ",
       "which was last viewed by ",
       $wf->context->param( 'last_viewer' ), " on ",
       $wf->context->param( 'last_view_date' );

=head2 Configuration

B<extra_table> (required)

Table where the extra data are kept.

B<extra_data_field> (required)

Can be a single field or a comma-separated list of fields, all in the
same table. If a single field specified you have the option of
declaring a different C<extra_context_key> under which the value
should be stored in the workflow context. Otherwise the values are
stored by the field names in the workflow context.

B<extra_context_key> (optional)

Key under which to save the data from C<extra_data_field> in the
workflow context.

Note: this is ignored when you specify multiple fields in
C<extra_data_field>; we just use the fieldnames for the context keys
in that case. And if you specify a single data field and do not
specify a context key we also use the data field name.

=head2 METHODS

=head3 init ( \%params )

Initializes persister for extra workflow data.

Throws L<Workflow::Exception> if initialization is not successful.

=head3 fetch_workflow ( $wf_id )

Fetches extra data from database and adds it to the restored workflow
context data returned with the fetched workflow.

Throws L<Workflow::Exception> if retrieval is not successful.

=head1 COPYRIGHT

Copyright (c) 2003-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
