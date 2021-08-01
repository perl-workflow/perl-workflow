#!/usr/bin/env perl

use warnings;
use strict;
use Test::More; # done_testing
use Test::Exception;
use Mock::MonkeyPatch;

use lib qw(t);
use TestUtil;
use TestDBUtil;

no warnings 'once';
require Log::Log4perl;
#Log::Log4perl::easy_init($Log::Log4perl::OFF);

eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
}

eval "require DBD::SQLite";
if ( $@ ) {
    plan skip_all => 'DBD::SQLite not installed';
}

TestDBUtil::create_tables({
                           db_type => 'sqlite',
                           db_file => 'workflow.db',
});

my $DATE_FORMAT = '%Y-%m-%d %H:%M';

require Workflow::Factory;
require_ok( 'Workflow::Persister::DBI::ExtraData' );

my @persisters = ({
    name              => 'TestPersister',
    class             => 'Workflow::Persister::DBI::ExtraData',
    dsn               => 'dbi:SQLite:dbname=db/workflow.db',
    user              => 'DBTester',
    date_format       => $DATE_FORMAT,
    autocommit        => 0,
    extra_table       => 'workflow_ticket',
    extra_data_field  => 'workflow_id,ticket_id',
    extra_context_key => 'ticket'
});

my $factory = Workflow::Factory->instance;
$factory->add_config( persister => \@persisters );
TestUtil->init_factory();

my $persister = $factory->get_persister( 'TestPersister' );

is ($persister->dsn(), 'dbi:SQLite:dbname=db/workflow.db', 'Got back dsn from config.');
is ($persister->date_format(), '%Y-%m-%d %H:%M', 'Got back date format from config.');
is ($persister->autocommit(), '0', 'Autocommit turned off by config.');

lives_ok { $factory->add_config( persister => \@persisters ) }
   'Successful persister creation' ;
TestUtil->init_factory();

ok(my $wf = $factory->create_workflow( 'Ticket' ), 'Creating workflow');

TestUtil->set_new_ticket_context( $wf );

ok($wf = $factory->fetch_workflow( 'Ticket', $wf->id ), 'Fetching workflow');

done_testing;
