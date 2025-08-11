package AutorunInitialObserver;

our @events;

sub callback {
    shift;
    push @events, [ @_ ];
}

1;
