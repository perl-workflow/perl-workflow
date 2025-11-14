#!/usr/bin/env perl

use strict;
use lib 't/lib';
use File::Path            qw( rmtree );
use File::Spec::Functions qw( curdir );
use File::Temp            qw( tempdir );
use Test::More  tests => 12;
use Test::Exception;

use Workflow::Context;
use Workflow::Factory qw( FACTORY );
use Workflow::Persister::File;

$Workflow::Condition::STRICT_BOOLEANS = 0;

my $persist_dir = tempdir( 'tmp_test_XXXX', DIR => curdir(), CLEANUP => 1 );


FACTORY()->add_config(
   action => [ { name => 'run', class => 'Workflow::Action::Null' } ],
   condition => [ { name => 'HasUser', class => 'TestApp::Condition::HasUserType' } ],
   persister => [ { name => 'Test', class => 'Workflow::Persister::File', path => $persist_dir  } ],
   workflow => {
      'type' => 'test',
      'persister' => 'Test',
      'description' => '',
      'state' => [
          { name => 'INITIAL',
            action => [ { name => 'run', resulting_state => 'INITIAL',
                          condition => [ { name => 'HasUser' },
                                         { name => '!HasUser' }
	                  ],
                        },
                      ],
          },
      ],
   }
   );

my $wf;
my $wf_state;
my $has_user;
my $not_has_user;
{
  local $Workflow::Condition::STRICT_BOOLEANS = 1;
  $wf = FACTORY->create_workflow( 'test' );
  dies_ok { Workflow::Condition->evaluate_condition( $wf, 'HasUser' ) },
     qr/did not return a valid result object/;
  dies_ok { Workflow::Condition->evaluate_condition( $wf, '!HasUser' ) },
     qr/did not return a valid result object/;

  $wf = FACTORY->create_workflow( 'test', Workflow::Context->new( current_user => 'me' ) );
  is(Workflow::Condition->evaluate_condition( $wf, 'HasUser' ), 1, 'strict bools/User/hasUser');
  is(Workflow::Condition->evaluate_condition( $wf, '!HasUser' ), 0, 'strict bools/User/!hasUser');
}

{
  local $Workflow::Condition::STRICT_BOOLEANS = 0;
  $wf = FACTORY->create_workflow( 'test' );
  lives_ok { is( Workflow::Condition->evaluate_condition( $wf, 'HasUser' ), 0, 'loose bools/noUser/hasUser') };
  lives_ok { is( Workflow::Condition->evaluate_condition( $wf, '!HasUser' ), 1, 'loose bools/noUser/!hasUser') };

  $wf = FACTORY->create_workflow( 'test', Workflow::Context->new( current_user => 'me' ) );
  lives_ok { is( Workflow::Condition->evaluate_condition( $wf, 'HasUser' ), 1, 'loose bools/User/hasUser') };
  lives_ok { is( Workflow::Condition->evaluate_condition( $wf, '!HasUser' ), 0, 'loose bools/User/!hasUser') };
}


END {
    if ( -d $persist_dir ) {
        rmtree( $persist_dir );
    }
}
