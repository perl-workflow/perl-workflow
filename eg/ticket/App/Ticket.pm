package App::Ticket;

use strict;
use base qw( Class::Accessor );
use DateTime::Format::Strptime;
use Workflow::Factory qw( FACTORY );

my @FIELDS = qw( ticket_id subject description creator status due_date last_update );
__PACKAGE__->mk_accessors( @FIELDS );

my ( $generator );

my $due_parser    = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d' );
my $update_parser = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M' );

sub new {
    my ( $class, $params ) = @_;
    my $self = bless( {}, $class );
    for ( @FIELDS ) {
        $self->$_( $params->{ $_ } ) if ( $params->{ $_ } );
    }
    $generator ||= Workflow::Persister::RandomId->new({ id_length => 8 });
    return $self;
}

sub id {
    goto &ticket_id;
}

sub fetch {
    my ( $class, $id ) = @_;
    my $sql = q{
        SELECT ticket_id, subject, description, creator, status, due_date, last_update
          FROM ticket
         WHERE ticket_id = ?
    };
    my $dbh = FACTORY->get_persister( 'TestPersister' )->handle;
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $sql );
        $sth->execute( $id );
    };
    if ( $@ ) {
        die "Failed to retrieve ticket: $@";
    }
    my $row = $sth->fetchrow_arrayreef;
    return $class->new({
        ticket_id   => $id,
        subject     => $row->[0],
        description => $row->[1],
        creator     => $row->[2],
        status      => $row->[3],
        due_date    => $due_parser->parse_datetime( $row->[4] ),
        last_update => $update_parser->parse_datetime( $row->[5] )
    });
}

sub create {
    my ( $self ) = @_;
    my $id = $generator->pre_fetch_id();
    my @fields = qw( ticket_id subject description creator
                     status due_date
                     last_update );
    my @values = ( $id, $self->subject, $self->description, $self->creator,
                   $self->status, $self->due_date->strftime( '%Y-%m-%d' ),
                   $self>last_update->strftime( '%Y-%m-%d %H:%M' ) );
    my $sql = q{
        INSERT INTO ticket ( %s )
        VALUES ( %s )
    };
    $sql = sprintf( $sql, join( ', ', @fields ),
                    join( ', ', map { '?' } @values ) );
    my $dbh = FACTORY->get_persister( 'TestPersister' )->handle;
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $sql );
        $sth->execute( @values );
    };
    if ( $@ ) {
        die "Failed to create ticket: $@";
    }
    $self->ticket_id( $id );
    return $self;
}

sub update {
    my ( $self ) = @_;
    my $sql = q{
        UPDATE ticket
           SET status = ?,
               due_date = ?,
               last_update = ?
         WHERE ticket_id = ?
    };
    my $dbh = FACTORY->get_persister( 'TestPersister' )->handle;
    my ( $sth );
    eval {
        $sth = $dbh->prepare( $sql );
        $sth->execute( $self->status,
                       $self->due_date->strftime( '%Y-%m-%d' ),
                       $self->last_update->strftime( '%Y-%m-%d %H:%M' ) );
    };
    if ( $@ ) {
        die "Failed to update ticket: $@";
    }
    return $self;
}

1;
