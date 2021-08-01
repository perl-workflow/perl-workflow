#!/usr/bin/env perl

use strict;
use lib qw(t);
use TestUtil;
use Test::More; # done_testing
use Test::Exception;
use Mock::MonkeyPatch;

no warnings 'once';


require Workflow::Factory;
require_ok( 'Workflow::Persister::DBI::AutoGeneratedId' );
require_ok( 'Workflow::Persister::DBI' );

my $DATE_FORMAT = '%Y-%m-%d %H:%M';

my @persisters = ({
    name  => 'MockPersister',
    class => 'Workflow::Persister::DBI',
    dsn   => 'DBI:Mock:',
    date_format => $DATE_FORMAT,
});

my $factory = Workflow::Factory->instance;

lives_ok { $factory->add_config( persister => \@persisters ) }
   'Successful persister creation' ;
TestUtil->init_factory();

my $persister = $factory->get_persister( 'MockPersister' );
my $handle = $persister->handle;

is ($persister->dsn(), 'DBI:Mock:', 'Got back DSN from config.');
is ($persister->date_format(), '%Y-%m-%d %H:%M', 'Got back date format from config.');

{
    # Oracle like, ref: Workflow::Persister::DBI
    my $generator = Workflow::Persister::DBI::SequenceId->new({ sequence_name => 'test_sequence', sequence_select => 'SELECT %s.NEXTVAL from dual' });
    is( ref( $generator ), 'Workflow::Persister::DBI::SequenceId',
        'Object created of correct type' );

    is($generator->post_fetch_id(), undef, 'Value returned from post_fetch_id' );

    # Mocking the sequence generation
    $handle->{mock_add_resultset} = {
        sql => qr/^SELECT test_sequence.NEXTVAL from dual/,
        results => [ [ 'dual' ], [ 1 ] ],
    };

    is($generator->pre_fetch_id($handle), 1, 'Calling pre_fetch_id');
}

done_testing();
