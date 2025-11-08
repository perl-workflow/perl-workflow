package Workflow::Persister::DBI::SequenceId;

use warnings;
use strict;
use v5.14.0;
use parent qw( Class::Accessor );
use DBI;
use Log::Any;
use Workflow::Exception qw( persist_error );
use Syntax::Keyword::Try;

$Workflow::Persister::DBI::SequenceId::VERSION = '2.07';

my @FIELDS = qw( log sequence_name sequence_select );
__PACKAGE__->mk_accessors(@FIELDS);


sub new {
    my ( $class, $params ) = @_;
    $params ||= {};
    $params->{log} = Log::Any->get_logger( category => $class );

    return bless { %{$params} }, $class;
}

sub pre_fetch_id {
    my ( $self, $dbh ) = @_;
    my $full_select = sprintf $self->sequence_select, $self->sequence_name;
    $self->log->debug("SQL to fetch sequence: ", $full_select);
    my ($row);
    try {
        my $sth = $dbh->prepare($full_select);
        $sth->execute;
        $row = $sth->fetchrow_arrayref;
        $sth->finish;
    }
    catch ($error) {
        persist_error "Failed to retrieve sequence: $error";
    }
    return $row->[0];
}

sub post_fetch_id {return}

1;

__END__

=pod

=head1 NAME

Workflow::Persister::DBI::SequenceId - Persister to fetch ID from a sequence

=head1 VERSION

This documentation describes version 2.07 of this package

=head1 SYNOPSIS

 <persister
     name="MyPersister"
     workflow_sequence="wf_seq"
     history_sequence="wf_history_seq"
 ...

=head1 DESCRIPTION

Implementation for DBI persister to fetch an ID value from a sequence.

=head2 Properties

B<sequence_name>

Name of the sequence to select the next id value from.

B<sequence_select>

C<sprintf> template string with a single placeholder (C<%s>) used to
interpolate the sequence name. The resulting string is used as the SQL
statement to retrieve the next sequence value.

=head2 ATTRIBUTES

=head3 log

Contains the logger object associated with this instance.

=head2 METHODS

=head3 new ( \%params )

This method instantiates a class for retrieval of sequence ids from a
L<DBI> based persistance entity.

It takes a hashref containing keys matching the properties outlines in the
section above or throws L<Workflow::Exception>s if these are not defined.

Returns instantiated object upon success.

=head3 pre_fetch_id

Returns a unique sequence id from a database.

Takes a single parameter, a L<DBI> database handle.

Returns a single value, a integer representing a sequence id from the provided
database handle.

=head3 post_fetch_id

This is a I<dummy> method, use L</pre_fetch_id>

=head1 COPYRIGHT

Copyright (c) 2003-2021 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Please see the F<LICENSE>

=head1 AUTHORS

Please see L<Workflow>

=cut
