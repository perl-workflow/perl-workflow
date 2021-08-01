
#!/usr/bin/env perl

use strict;
use lib qw(t);
use TestUtil;
use Test::More  tests => 1;

no warnings 'once';


my $wf;

require_ok( 'Workflow::Condition::Evaluate' );

#ok(my $condition = Workflow::Condition::Evaluate->new( test => '' ));

#isa_ok($condition, 'Workflow::Condition::Evaluate');

#ok($condition->evaluate($wf));
