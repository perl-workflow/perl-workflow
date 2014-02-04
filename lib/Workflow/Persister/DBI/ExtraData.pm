package Workflow::Persister::DBI::ExtraData;

# $Id$

use warnings;
use strict;
use base qw( Workflow::Persister::DBI );
use Log::Log4perl qw( get_logger );
use Workflow::Exception qw( configuration_error persist_error );
use English qw( -no_match_vars );

$Workflow::Persister::DBI::ExtraData::VERSION = '1.05';

my @FIELDS = qw( table data_field context_key );
__PACKAGE__->mk_accessors(@FIELDS);

sub init {
    my ( $self, $params ) = @_;
    $self->SUPER::init($params);
    my $log = get_logger();

    my @not_found = ();
    foreach (qw( table data_field )) {
        push @not_found, $_ unless ( $params->{"extra_$_"} );
    }
    if ( scalar @not_found ) {
        $log->error( "Required configuration fields not found: ",
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
    $log->is_info
        && $log->info( "Configured extra data fetch with: ",
        join '; ', $self->table, $data_field, $self->context_key );
}

sub fetch_extra_workflow_data {
    my ( $self, $wf ) = @_;
    my $log = get_logger();

    $log->is_debug
        && $log->debug( "Fetching extra workflow data for '", $wf->id, "'" );

    my $sql = q{
       SELECT %s FROM %s
        WHERE workflow_id = ?
    };
    my $data_field = $self->data_field;
    my $select_data_fields
        = ( ref $data_field )
        ? join( ', ', @{$data_field} )
        : $data_field;
    $sql = sprintf $sql, $select_data_fields, $self->table;
    $log->is_debug
        && $log->debug("Using SQL\n$sql");
    $log->is_debug
        && $log->debug( "Bind parameters: ", $wf->id );

    my ($sth);
    eval {
        $sth = $self->handle->prepare($sql);
        $sth->execute( $wf->id );
    };
    if ($EVAL_ERROR) {
        persist_error "Failed to retrieve extra data from table ",
            $self->table, ": $EVAL_ERROR";
    } else {
        $log->is_debug
            && $log->debug("Prepared/executed extra data fetch ok");
        my $row = $sth->fetchrow_arrayref;
        if ( ref $data_field ) {
            ## no critic (ProhibitCStyleForLoops)
            for ( my $i = 0; $i < scalar @{$data_field}; $i++ ) {
                $wf->context->param( $data_field->[$i], $row->[$i] );
                $log->is_info
                    && $log->info(
                    sprintf "Set data from %s.%s into context key %s ok",
                    $self->table, $data_field->[$i], $data_field->[$i] );
            }
        } else {
            my $value = $row->[0];
            $wf->context->param( $self->context_key, $value );
            $log->is_info
                && $log->info(
                sprintf "Set data from %s.%s into context key %s ok",
                $self->table, $self->data_field, $self->context_key );
        }
    }
}

1;

__END__

=head1 NAME

Workflow::Persister::DBI::ExtraData - Fetch extra data with each workflow and put it into the context

=head1 VERSION

This documentation describes version 1.05 of this package

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

=head2 Overview

Simple subclass of L<Workflow::Persister::DBI> to allow you to declare
an extra table and data field(s) from which to fetch data whenever you
fetch a workflow. There is a simple restriction: the table must have a
field 'workflow_id' of the same datatype as the 'workflow_id' field in
the 'workflow' table.

=head2 Examples

 # Specify a single field 'ticket_id' from the table 'workflow_ticket'
 # and store it in the context using the same key:
 
 <persister
     ...
     extra_table="workflow_ticket"
     extra_data_field="ticket_id"
     ...
 
 # How you would use this:
 my $wf = FACTORY->fetch_workflow( 'Ticket', 55 );
 print "Workflow is associated with ticket: ",
       $wf->context->param( 'ticket_id' );

 # Specify a single field 'ticket_id' from the table 'workflow_ticket'
 # and store it in the context using a different key
 
 <persister
     ...
     extra_table="workflow_ticket"
     extra_data_field="ticket_id"
     extra_context_key="THE_TICKET_ID"
     ...
 
 # How you would use this:
 my $wf = FACTORY->fetch_workflow( 'Ticket', 55 );
 print "Workflow is associated with ticket: ",
       $wf->context->param( 'THE_TICKET_ID' );
 
 # Specify multiple fields ('ticket_id', 'last_viewer',
 # 'last_view_date') to pull from the 'workflow_ticket' table:
 
 <persister
     ...
     extra_table="workflow_ticket"
     extra_data_field="ticket_id,last_viewer,last_view_date"
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

=head3 fetch_extra_workflow_data ( $wf )

Fetches extra data from database and feeds this to context of given workflow.

Takes a single parameter, a workflow object to which extra data are feed if
retrieved successfully.

Throws L<Workflow::Exception> if retrieval is not successful.

=head1 COPYRIGHT

Copyright (c) 2003-2007 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jonas B. Nielsen (jonasbn) E<lt>jonasbn@cpan.orgE<gt> is the current maintainer.

Chris Winters E<lt>chris@cwinters.comE<gt>, original author.

=cut
