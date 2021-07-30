#!/usr/bin/env perl

use strict;
use lib qw(t);
use TestUtil;
use Test::Exception;
use Test::More  tests => 6;

no warnings 'once';
require Log::Log4perl;
Log::Log4perl::easy_init($Log::Log4perl::OFF);


require_ok( 'Workflow::Persister' );

dies_ok { Workflow::Persister->create_workflow(); };

dies_ok { Workflow::Persister->update_workflow(); };

dies_ok { Workflow::Persister->fetch_workflow(); };

dies_ok { Workflow::Persister->create_history(); };

dies_ok { Workflow::Persister->fetch_history(); };
