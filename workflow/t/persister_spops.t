# -*-perl-*-

# $Id$

use strict;
use constant NUM_TESTS => 1;
use Test::More;

eval "require SPOPS";
if ( $@ ) {
    plan skip_all => 'SPOPS not installed';
}
plan tests => NUM_TESTS;

require_ok( 'Workflow::Persister::SPOPS' );

my $WF_CLASS   = 'My::Persist::Workflow';
my $HIST_CLASS = 'My::Persist::WorkflowHistory';

my $original_time = '2004-02-02 02:22:12';

my $classes = spops_initialize() || [];
unless ( scalar @{ $classes } == 1 ) {
    die "Did not initialize classes properly: ", join( ', ', @{ $classes } ), "\n";
}



sub spops_initialize {
    my $date_format = '%Y-%m-%d %H:%M:%S';
    my %config = (
        workflow => {
            class               => $WF_CLASS,
            isa                 => [ 'SPOPS::Key::Random', 'SPOPS::Loopback' ],
            rules_from          => [ 'SPOPS::Tool::DateConvert' ],
            field               => [
                qw( workflow_id type state last_update )
            ],
            id_field            => 'workflow_id',
            convert_date_class  => 'DateTime',
            convert_date_format => $date_format,
            convert_date_field  => [ 'last_update' ],
        },
        workflow_history => {
            class               => $HIST_CLASS,
            isa                 => [ 'SPOPS::Key::Random', 'SPOPS::Loopback' ],
            rules_from          => [ 'SPOPS::Tool::DateConvert' ],
            field               => [
                qw( workflow_hist_id workflow_id action description
                    state user history_date )
            ],
            id_field            => 'workflow_hist_id',
            convert_date_class  => 'DateTime',
            convert_date_format => $date_format,
            convert_date_field  => [ 'history_date' ],
        },
    );
    require SPOPS::Initialize;
    return SPOPS::Initialize->process({ config => \%config });
}
