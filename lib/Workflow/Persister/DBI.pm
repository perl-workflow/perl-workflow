package Workflow::Persister::DBI;

# $Id$

use strict;
use base qw( Workflow::Persister );
use Log::Log4perl       qw( get_logger );
use Workflow::Exception qw( configuration_error persist_error );

$Workflow::Persister::DBI::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

my @FIELDS = qw( handle dsn user password driver
                 workflow_table history_table
                 workflow_id_generator history_id_generator );
__PACKAGE__->mk_accessors( @FIELDS );

sub init {
    my ( $self, $params ) = @_;
    unless ( $params->{dsn} ) {
        configuration_error "DBI persister configuration must include ",
                            "key 'dsn' which maps to the first paramter ",
                            "in the DBI 'connect()' call.";
    }
    my ( $dbi, $driver, $etc ) = split ':', $params->{dsn}, 3;
    $self->driver( $driver );

    for ( @FIELDS ) {
        $self->$_( $params->{ $_ } ) if ( $params->{ $_ } );
    }

    my ( $wf_gen, $hist_gen );
    if ( $driver eq 'Pg' ) {
        ( $wf_gen, $history_gen ) =
            $self->_init_postgres_generators( $params );
    }
    elsif ( $driver eq 'mysql' ) {
        ( $wf_gen, $history_gen ) =
            $self->_init_mysql_generators( $params );
    }
    elsif ( $driver eq 'SQLite' ) {
        ( $wf_gen, $history_gen ) =
            $self->_init_sqlite_generators( $params );
    }
    else {
        ( $wf_gen, $history_gen ) =
            $self->_init_random_generators( $params );
    }
    $self->workflow_generator( $wf_gen );
    $self->history_generator( $history_gen );

    unless ( $self->workflow_table ) {
        $self->workflow_table( 'workflow' );
    }
    unless ( $self->history_table ) {
        $self->history_table( 'workflow_history' );
    }

    my $dbh = eval {
        DBI->connect( $self->dsn, $self->user, $self->password )
            || die "Cannot connect to database: $DBI::errstr";
    };
    if ( $@ ) {
        perist_error $@;
    }
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    $db->{ChopBlanks}  = 1;
    $db->{AutoCommit}  = 1;
    $self->handle( $dbh );
    return $self;
}

sub create_workflow {
    my ( $self, $wf ) = @_;
    my $log = get_logger();
    my @fields = ( 'type',
                   'state',
                   'last_update' );
    my @values = ( $self->type,
                   $self->state,
                   DateTime->now->strftime( '%Y-%m-%d %H:%M' ) );
    my $id = $self->workflow_generator->pre_fetch_id;
    if ( $id ) {
        push @fields, 'workflow_id';
        push @values, $id;
        $log->debug( "Got ID from pre_fetch_id: $id" );
    }
    my $sql = 'INSERT INTO ' . $self->workflow_table . "\n" .
              '( ' . join( ', ', @fields ) . " )\n" .
              ' VALUES ( ' . join( ', ', map { '?' } 0 .. ( scalar @fields - 1 ) ) . ')';
    $log->debug( "Will use SQL\n$sql" );
    $log->debug( "Will use parameters\n", join( ', ', @values ) );

    my ( $sth );
    eval {
        $sth = $self->handle->prepare( $sql );
        $self->execute( @values );
    };
    if ( $@ ) {
        persist_error "Failed to create workflow: $@";
    }
    unless ( $id ) {
        $id = $self->workflow_generator->post_fetch_id( $dbh, $sth );
        unless ( $id ) {
            persist_error "No ID found using generator '",
                          ref( $self->workflow_generator ), "'";
        }
    }
    $sth->finish;
    return $id;
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

########################################
# GENERATOR INIT

sub _init_postgres_generators {
    my ( $self, $params ) = @_;
    my $sequence_select = q{SELECT NEXTVAL( '%s' )};
    $params->{workflow_sequence} ||= 'workflow_seq';
    $params->{history_sequence}  ||= 'workflow_history_seq';
    return (
        Workflow::Persister::DBI::SequenceId->new(
            { sequence_name   => $params->{workflow_sequence},
              sequence_select => $sequence_select }),
        Workflow::Persister::DBI::SequenceId->new(
            { sequence_name   => $params->{history_sequence},
              sequence_select => $sequence_select })
    );
}

sub _init_mysql_generators {
    my ( $self, $params ) = @_;
    my $generator =
        Workflow::Persister::DBI::AutoGeneratedId->new(
            { from_handle     => 'database',
              handle_property => 'mysql_insertid' });
    return ( $generator, $generator );
}

sub _init_sqlite_generators {
    my ( $self, $params ) = @_;
    my $generator =
        Workflow::Persister::DBI::AutoGeneratedId->new(
            { func_property => 'last_insert_rowid' });
    return ( $generator, $generator );
}

sub _init_random_generators {
    my ( $self, $params ) = @_;
    my $generator =
        Workflow::Persister::DBI::RandomId->new({ id_length => 8 });
    return ( $generator, $generator );
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
            dsn="DBI:Pg:dbname=workflows"
            user="wf"
            password="mypass"
            workflow_table="wf"
            workflow_sequence="wf_seq"
            history_table="wf_history"
            history_sequence="wf_history_seq"/>
 

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