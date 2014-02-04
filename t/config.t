# -*-perl-*-

# $Id$

use strict;
use lib 't';
use TestUtil;
use Test::More  tests => 50;
use Test::Exception;

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
		  'workflow' => ['workflow.xml', 'workflow_type.xml'],
		  'action' => ['workflow_action.xml', 'workflow_action_type.xml'],
		  'condition' => ['workflow_condition.xml', 'workflow_condition_type.xml'],
		  'validator' => ['workflow_validator.xml'],
		  'persister' => ['workflow_persister.xml'],
		 );

for my $type ( sort keys %config_xml ){
  for my $source ( @{$config_xml{$type}} ){

    my @config = $parser->parse( $type, $source );
    ok( $config[0], "Parsed a config from $source for $type.");
    is( (ref $config[0]), 'HASH', 'Got a hashref.');
  }
}

$parser = Workflow::Config->new( 'xml' );
ok($parser->parse( 'workflow', 'workflow.xml', 'workflow_type.xml', 'workflow_action.xml', 'workflow_action_type.xml', 'workflow_condition.xml', 'workflow_condition_type.xml', 'workflow_validator.xml' ));

#testing good config language Perl
ok($parser = Workflow::Config->new( 'perl' ));
isa_ok($parser, 'Workflow::Config');

dies_ok { $parser->parse( 'workflow', 'workflow_errorprone.perl' ) };
dies_ok { $parser->parse( 'workflow', 'no_such_file.perl' ) };
dies_ok { $parser->parse( '123_NOSUCHTYPE', 'workflow_errorprone.perl' ) };

dies_ok { Workflow::Config->parse() };

my @config = $parser->parse( 'workflow' );
is(scalar(@config), 0, 'forgotten file, asserting length of array returned'); 

my %config_perl = (
		   'workflow' => ['workflow.perl', 'workflow_type.perl', 'workflow_type_alternate_initial.perl'],
		   'action' => ['workflow_action.perl'],
		   'condition' => ['workflow_condition.perl', 'workflow_condition_type.perl'],
		   'validator' => ['workflow_validator.perl'],
		   'persister' => ['workflow_persister.perl'],
		 );

for my $type ( sort keys %config_perl ){
  for my $source ( @{$config_perl{$type}} ){

    my @config = $parser->parse( $type, $source );
    ok( $config[0], "Parsed a config from $source for $type.");
    is( (ref $config[0]), 'HASH', 'Got a hashref.');
  }
}

$parser = Workflow::Config->new( 'perl' );
ok($parser->parse( 'workflow', 'workflow.perl', 'workflow_action.perl', 'workflow_condition.perl', 'workflow_validator.perl' ));

#testing class method parse_all_files
my @array = Workflow::Config->parse_all_files();
is(scalar @array, 0, 'asserting return value');

dies_ok { Workflow::Config->parse_all_files( '123_NOSUCHTYPE', 'workflow_condition.prl' ) };

ok(Workflow::Config->parse_all_files( 'workflow', 'workflow_condition.perl', 'workflow_validator.perl' ));
