#!perl

use v5.14.0;
use strict;
use warnings;

use Test::More;

if ( not exists $ENV{POD_LINKS} ) {
    plan skip_all => 'Environment variable POD_LINKS not set';
}

require Test::Pod::Links
    or plan skip_all => 'Test::Pod::Links not installed';


Test::Pod::Links->new->all_pod_files_ok;
