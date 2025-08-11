#!/usr/bin/env perl

use strict;
use lib 't/lib';
use TestUtil;
use Test::Exception;
use Test::More  tests => 18;

no warnings 'once';


require_ok( 'Workflow::Persister' );

dies_ok { Workflow::Persister->create_workflow(); };

dies_ok { Workflow::Persister->update_workflow(); };

dies_ok { Workflow::Persister->fetch_workflow(); };

dies_ok { Workflow::Persister->create_history(); };

dies_ok { Workflow::Persister->fetch_history(); };

my $persister;

$persister = Workflow::Persister->new(
    {
        name       => 'random persister',
        class      => 'Workflow::Persister',
        use_random => 'yes',
    });

is( ref($persister), 'Workflow::Persister' );
is( $persister->class, 'Workflow::Persister' );
is( $persister->use_random, 'yes' );
is( $persister->use_uuid, 'no' );

dies_ok {
    eval "use Test::Without::Module qw( Workflow::Persister::RandomId )";
    $persister->assign_generators;
}, qr{Can't locate Workflow/Persister/RandomId.pm};

lives_ok {
    eval "no Test::Without::Module qw( Workflow::Persister::RandomId )";
    $persister->assign_generators;
};


$persister = Workflow::Persister->new(
    {
        name       => 'random persister',
        class      => 'Workflow::Persister',
        use_uuid   => 'yes',
    });

is( ref($persister), 'Workflow::Persister' );
is( $persister->class, 'Workflow::Persister' );
is( $persister->use_random, 'no' );
is( $persister->use_uuid, 'yes' );

dies_ok {
    eval "use Test::Without::Module qw( Workflow::Persister::UUID )";
    $persister->assign_generators;
}, qr{Can't locate Workflow/Persister/RandomId.pm};

lives_ok {
    eval "no Test::Without::Module qw( Workflow::Persister::UUID )";
    $persister->assign_generators;
};

