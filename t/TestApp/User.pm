package TestApp::User;

# $Id$

use strict;

$TestApp::User::VERSION = '0.01';

my %USERS = (
    Stu => 'Stu Nahan',
    Mel => 'Mel Ott',
    Irv => 'Irv Cross',
    Bob => 'Bobby Orr',
    Joe => 'Joe Morgan',
    Ric => 'Ric Ocasek'
);

sub get_possible_values {
    return map { { value => $_, label => $USERS{ $_ } } } sort keys %USERS;
}

1;
