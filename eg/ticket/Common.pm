package Common;

use strict;
use DBI;

my ( $DB );

sub global_datasource_handle {
    return $DB if ( $DB );
    no strict 'vars';
    my $config = do 'db_config.pl';
    $DB = DBI->connect( $config->{dsn}, $config->{user}, $config->{pass} )
                        || die "Cannot connect to database: $DBI::errstr";
    $DB->{AutoCommit} = 1;
    $DB->{RaiseError} = 1;
    return $DB;
}

1;
