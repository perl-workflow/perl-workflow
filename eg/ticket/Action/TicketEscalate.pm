package Action::TicketEscalate;

# $Id$

use strict;
use base qw( Workflow::Action );
use Log::Log4perl qw( get_logger );

$Action::TicketEscalate::VERSION  = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);

sub execute {
    my ( $self ) = @_;
    my $log = get_logger();
    $log->debug( "Action '", $self->name, "' with class '", ref( $self ), "' executing..." );
}

1;

__END__
