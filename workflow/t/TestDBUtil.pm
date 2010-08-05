package TestDBUtil;

use strict;
use warnings;

use Log::Log4perl     qw( get_logger );
use Cwd               qw( cwd );
use File::Spec::Functions;

########################################
# DB INIT

sub create_tables {
  my $arg_ref = shift;
    my $log = get_logger();
    my ( $dbh, @tables ) = initialize_db($arg_ref);
    for ( @tables ) {
        next if ( /^\s*$/ );
        $log->debug( "Creating table:\n$_" );
        eval { $dbh->do( $_ ) };
        if ( $@ ) {
            die "Failed to create table\n$_\n$@\n";
        }
    }
    $log->info( 'Created tables ok' );
}

sub initialize_db {
  my $arg_ref = shift;
  my $log = get_logger();

  # Get the base workflow directory.
  my $workflow_base = cwd();
  
  #we are called from the examples directory
  if ($workflow_base =~ m[/eg/ticket]) {
    $workflow_base =~ s/\A(.*)\/eg\/ticket/$1/;
  } else {
    $workflow_base =~ s/\A(.*)\/t/$1/;
  }

    my $path = catdir( cwd(), 'db' );
    unless( -d $path ) {
        mkdir( $path, 0777 ) || die "Cannot create directory '$path': $!";
        $log->info( "Created db directory '$path' ok" );
    }

    my ( $dbh );
  my $DB_FILE = $arg_ref->{db_file};
    my @tables = ();
    if ( $arg_ref->{db_type} eq 'sqlite' ) {
      if ( -f "$path/$DB_FILE" ) {
            $log->info( "Removing old database file..." );
            unlink( "$path/$DB_FILE" );
        }
        my $DSN = "DBI:SQLite:dbname=db/$DB_FILE";
        $log->info( "Connecting to SQLite database with DSN '$DSN'..." );
        $dbh = DBI->connect( $DSN, '', '',
                             { RaiseError => 1, PrintError => 0 } )
                    || die "Cannot create database: $DBI::errstr\n";
        $log->info( "Connected to database ok" );
        @tables = (
            read_tables( "$workflow_base/struct/workflow_sqlite.sql" ),
            read_tables( "$workflow_base/eg/ticket/ticket.sql" )
        );
    }
    elsif ( $arg_ref->{db_type} eq 'csv' ) {
        my @names = qw( workflow workflow_history ticket workflow_ticket );
        for ( @names ) {
            if ( -f $_ ) {
                $log->info( "Removing old database file '$_'..." );
                unlink( $_ );
            }
        }
        $dbh = DBI->connect( "DBI:CSV:f_dir=db", '', '' )
                    || die "Cannot create database: $DBI::errstr\n";
        $dbh->{RaiseError} = 1;
        $log->info( "Connected to database ok" );
        @tables = (
            read_tables( "$workflow_base/struct/workflow_csv.sql" ),
            read_tables( "$workflow_base/eg/ticket/ticket_csv.sql" )
        );
    }
    return ( $dbh, @tables );
}

########################################
# I/O

sub read_tables {
    my ( $file ) = @_;
    my $table_file = read_file( $file );
    return split( ';', $table_file );
}

sub read_file {
    my ( $file ) = @_;
    local $/ = undef;
    open( IN, '<', $file ) || die "Cannot read '$file': $!";
    my $content = <IN>;
    close( IN );
    return $content;
}

=head1 TestDBUtil

This file contains some utilities to help you easily create a
test SQLite database for a sample workflow application. These
utilities are used in the test ticket application and in
the system tests.

=cut


1;
