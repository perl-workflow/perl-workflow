# -*-perl-*-

# $Id: Persister.t 304 2007-07-03 14:56:43Z jonasbn $

use strict;
use lib 't';
use TestUtil;
use Test::Exception;
use Test::More  tests => 6;

require_ok( 'Workflow::Persister' );

dies_ok { Workflow::Persister->create_workflow(); };

dies_ok { Workflow::Persister->update_workflow(); };

dies_ok { Workflow::Persister->fetch_workflow(); };

dies_ok { Workflow::Persister->create_history(); };

dies_ok { Workflow::Persister->fetch_history(); };
