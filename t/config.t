#!/usr/bin/env perl

use strict;
use lib qw(t);
use TestUtil;
use Test::More  tests => 55;
use Test::Exception;

no warnings 'once';


my ($parser);

#testing load
require_ok( 'Workflow::Config' );

#testing bad config language,SCAML it is a disgrace to mark-up
dies_ok { Workflow::Config->new( 'SCAML' ) };

#testing good config language XML
ok($parser = Workflow::Config->new( 'xml' ));

ok(my @validtypes = $parser->get_valid_config_types());
is( $validtypes[0], 'action', 'Got array with valid types and action is first.');

isa_ok($parser, 'Workflow::Config');

my %config_xml = (
                  'workflow' => ['t/workflow.xml', 't/workflow_type.xml'],
                  'action' => ['t/workflow_action.xml', 't/workflow_action_type.xml'],
                  'condition' => ['t/workflow_condition.xml', 't/workflow_condition_type.xml'],
                  'validator' => ['t/workflow_validator.xml'],
                  'persister' => ['t/workflow_persister.xml'],
                  'observer' => ['t/workflow_independent_observers.xml'],
                 );

for my $type ( sort keys %config_xml ){
  for my $source ( @{$config_xml{$type}} ){

    my @config = $parser->parse( $type, $source );
    ok( $config[0], "Parsed a config from $source for $type.");
    is( (ref $config[0]), 'HASH', 'Got a hashref.');
  }
}

$parser = Workflow::Config->new( 'xml' );
ok($parser->parse( 'workflow', 't/workflow.xml', 't/workflow_type.xml', 't/workflow_action.xml', 't/workflow_action_type.xml', 't/workflow_condition.xml', 't/workflow_condition_type.xml', 't/workflow_validator.xml', 't/workflow_independent_observers.xml' ));

#testing good config language Perl
ok($parser = Workflow::Config->new( 'perl' ));
isa_ok($parser, 'Workflow::Config');

dies_ok { $parser->parse( 'workflow', 't/workflow_errorprone.perl' ) };
dies_ok { $parser->parse( 'workflow', 't/no_such_file.perl' ) };
dies_ok { $parser->parse( '123_NOSUCHTYPE', 't/workflow_errorprone.perl' ) };

dies_ok { Workflow::Config->parse() };

my @config = $parser->parse( 'workflow' );
is(scalar(@config), 0, 'forgotten file, asserting length of array returned');

my %config_perl = (
                   'workflow' => ['t/workflow.perl', 't/workflow_type.perl', 't/workflow_type_alternate_initial.perl'],
                   'action' => ['t/workflow_action.perl'],
                   'condition' => ['t/workflow_condition.perl', 't/workflow_condition_type.perl'],
                   'validator' => ['t/workflow_validator.perl'],
                   'persister' => ['t/workflow_persister.perl'],
                   'observer' => ['t/workflow_independent_observers.perl'],
                 );

for my $type ( sort keys %config_perl ){
  for my $source ( @{$config_perl{$type}} ){

    my @config = $parser->parse( $type, $source );
    ok( $config[0], "Parsed a config from $source for $type.");
    is( (ref $config[0]), 'HASH', 'Got a hashref.');
  }
}

$parser = Workflow::Config->new( 'perl' );
ok($parser->parse( 'workflow', 't/workflow.perl', 't/workflow_action.perl', 't/workflow_condition.perl', 't/workflow_validator.perl' ));

$parser = Workflow::Config->new( 'yaml' );
ok($parser->parse( 'workflow', 't/workflow.yaml', 't/workflow_action.yaml', 't/workflow_condition.yaml', 't/workflow_validator.yaml' ));

#testing class method parse_all_files
my @array = Workflow::Config->parse_all_files();
is(scalar @array, 0, 'asserting return value');

dies_ok { Workflow::Config->parse_all_files( '123_NOSUCHTYPE', 't/workflow_condition.prl' ) };

ok(Workflow::Config->parse_all_files( 'workflow', 't/workflow_condition.perl', 't/workflow_validator.perl' ));
