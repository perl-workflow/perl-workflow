#!/usr/bin/perl 

# $Id$

use strict;
use lib 't';
use TestUtil;
use constant NUM_TESTS => 4;
use Test::More;
use Test::Exception;

plan tests => NUM_TESTS;

require Workflow::Factory;

my @conditions = ({
         name => 'HasUser',
         class => 'TestApp::Condition::HasUser'
       },
       {
         name => 'HasUserType',
         class => 'TestApp::Condition::HasUserType'
       },
);

my @actions = ({
         name => 'TIX_NEW',
         class => 'TestApp::Action::TicketCreate'
       });

my $factory = Workflow::Factory->instance();

is( ref( $factory ), 'Workflow::Factory',
   'Return from instance() correct type' );

$factory->add_config( condition  => \@conditions );
lives_ok{$factory->get_condition('HasUser')};

$factory->add_config( action  => \@actions );
ok(exists $factory->{_action_config}, "action config added");

#additional tests

my @validators = ({
         name => 'DateValidator',
         class => 'Workflow::Validator::MatchesDateFormat',
         date_format => '%Y-%m-%d %H:%M',
       });

$factory->add_config( validator  => \@validators );
ok(exists $factory->{_validator_config}, "validator config added");
