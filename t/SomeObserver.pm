package SomeObserver;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

my @observations = ();

sub get_observations {
    return @observations;
}

sub clear_observations {
    @observations = ();
}

sub update {
    my ( $class, $workflow, $action, @extra ) = @_;
    push @observations, [ 'class', $workflow, $action, @extra ];
}

sub other_sub {
    my ( $workflow, $action, @extra ) = @_;
    push @observations, [ 'sub', $workflow, $action, @extra ];
}

1;
