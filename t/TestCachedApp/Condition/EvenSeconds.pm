package TestCachedApp::Condition::EvenSeconds;

# $Id$

use strict;
use base qw( Workflow::Condition );
use Workflow::Exception qw( condition_error );

sub evaluate {
    my ( $self, $wf ) = @_;
    sleep 1;
    if (time() % 2 == 1) {
        condition_error "Current seconds are not divisible by 2";
    }
}

1;
