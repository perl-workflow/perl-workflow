package Workflow::Persister::DBI::SequenceId;

# $Id$

use strict;
use base qw( Class::Accessor );
use DBI;
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( persist_error );

$Workflow::Persister::DBI::SequenceId::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( sequence_name sequence_select );
__PACKAGE__->mk_accessors( @FIELDS );

my ( $log );

sub pre_fetch_id {
    my ( $self, $dbh ) = @_;
    $log ||= get_logger();
    my $full_select = sprintf( $self->sequence_select, $self->sequence_name );
    $log->is_debug &&
        $log->debug( "SQL to fetch sequence: $full_select" );
    my ( $row );
    eval {
        my $sth = $dbh->prepare( $full_select );
        $sth->execute;
        $row = $sth->fetchrow_arrayref;
        $sth->finish;
    };
    if ( $@ ) {
        persist_error "Failed to retrieve sequence: $@";
    }
    return $row->[0];
}

sub post_fetch_id { return }

1;

__END__

=head1 NAME

Workflow::Persister::DBI::SequenceId - Persister to fetch ID from a sequence

=head1 SYNOPSIS

 <persister
     name="MyPersister"
     workflow_sequence="wf_seq"
     history_sequence="wf_history_seq"
 ...

=head1 DESCRIPTION

Implementation for DBI persister to fetch an ID value from a sequence.

=head2 METHODS

#=head3 pre_fetch_id

#=head3 post_fetch_id

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
