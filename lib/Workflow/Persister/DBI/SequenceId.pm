package Workflow::Persister::DBI::SequenceId;

# $Id$

use strict;
use base qw( Class::Accessor );

$Workflow::Persister::DBI::SequenceId::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( sequence_name sequence_select );
__PACKAGE__->mk_accessors( @FIELDS );

sub pre_fetch_id {
    my ( $self, $dbh ) = @_;
    my $full_select = sprintf( $self->sequence_select, $self->sequence_name );
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $full_select );
        $sth->execute;
    };
    my $row = $sth->fetchrow_arrayref;
    $sth->finish;
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

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
