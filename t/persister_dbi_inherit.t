#!/usr/bin/env perl

use strict;
use lib qw(t);
use Test::More;


eval "require DBI";
if ( $@ ) {
    plan skip_all => 'DBI not installed';
}
plan tests => 7;


my $TICKET_CLASS = 'TestApp::Ticket';
my $DATE_FORMAT = '%Y-%m-%d %H:%M';

require_ok( 'PersisterDBIOtherFields' );
require_ok( 'Workflow::Persister::DBI' );
require_ok( 'Workflow::Factory' );


my @persisters = (
    {
        class  => 'Workflow::Persister::DBI',
        name   => 'Regular',
        dsn    => 'dbi:Mock:'
    },
    {
        class  => 'PersisterDBIOtherFields',
        name   => 'Other',
        dsn    => 'dbi:Mock:'
    }
    );

my $wf_config_main = {
    type        => 'main',
    description => 'main',
    persister   => 'Regular',
    state       => [
        {
            name => 'INITIAL',
        },
        ],
};
my $wf_config_other = {
    type        => 'other',
    description => 'other',
    persister   => 'Other',
    state       => [
        {
            name => 'INITIAL',
        },
        ],
};

my $factory = Workflow::Factory->instance;
$factory->add_config( persister => \@persisters );
$factory->add_config( workflow  => $wf_config_main );
$factory->add_config( workflow  => $wf_config_other );

my $wf_main  = $factory->create_workflow( 'main' );
my $wf_other = $factory->create_workflow( 'other' );


my $main_history  = $factory->get_persister( 'Regular' )->handle->{mock_all_history};
my $other_history = $factory->get_persister( 'Other' )->handle->{mock_all_history};

like( $main_history->[0]->{statement},
      qr/\QINSERT INTO "workflow" ( "type", "state", "last_update", "workflow_id" ) \E/,
      'Regular workflow field names used with standard DBI persister');
like( $other_history->[0]->{statement},
      qr/\QINSERT INTO "workflow" ( "w2", "w3", "w4", "w1" ) \E/,
      'Overridden workflow field names used with DBI-persister derived class');

like( $main_history->[1]->{statement},
      qr/\QINSERT INTO "workflow_history" ( "workflow_id", "action", "description", "state", "workflow_user", "history_date", "workflow_hist_id" ) \E/,
      'Regular history field names used with standard DBI persister');
like( $other_history->[1]->{statement},
      qr/\QINSERT INTO "workflow_history" ( "h2", "h3", "h4", "h5", "h6", "h7", "h1" ) \E/,
      'Overridden history field names used with DBI-persister derived class');


