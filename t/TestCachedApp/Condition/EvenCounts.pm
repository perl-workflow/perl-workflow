package TestCachedApp::Condition::EvenCounts;

# $Id$

use strict;
use base qw( Workflow::Condition );
use Workflow::Exception qw( condition_error );

our $count = 0;

sub evaluate {
    my ( $self, $wf ) = @_;
    if ($count++ % 2 == 1) {
        condition_error "Current count is not divisible by 2";
    }
}

1;
