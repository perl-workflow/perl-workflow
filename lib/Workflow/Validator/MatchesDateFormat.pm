package Workflow::Validator::MatchesDateFormat;

use strict;
use base qw( Workflow::Validator );
use DateTime::Format::Strptime;
use Workflow::Exception qw( configuration_error validation_error );

__PACKAGE__->mk_accessors( 'formatter' );

sub _init {
    my ( $self, $params ) = @_;
    unless ( $params->{date_format} ) {
        configuration_error
            "You must define a value for 'date_format' in ",
            "declaration of validator ", $self->name;
    }
    if ( ref $params->{date_format} ) {
        configuration_error
            "The value for 'date_format' must be a simple scalar in ",
            "declaration of validator ", $self->name;
    }
    my $formatter = DateTime::Format::Strptime->new(
                             pattern => $params->{date_format},
                             on_error => 'undef' );
    $self->formatter( $formatter );
}

sub validate {
    my ( $self, $wf, $date_string ) = @_;
    my $fmt = $self->formatter;
    my $date_object = $fmt->parse_datetime( $date_string );
    unless ( $date_object ) {
        validation_error
            "Date '$date_string' does not match required pattern '", $fmt->pattern, "'";
    }
}

1;

__END__

=head1 NAME

Workflow::Validator::MAtchesDateFormat - Ensure a stringified date matches a given pattern

=head1 SYNOPSIS

 <action name="CreateNews">
   <validator name="DateFormat">
      <param name="date_format" value="%Y-%m-%d"/>
      <arg value="$news_post_date"/>
   </validator>
 </action>

=head1 DESCRIPTION

This validator ensures that a given date string matches a C<strptime>
pattern. The parameter 'date_format' is used to declare the pattern
against which the date string must be matched, and the single argument
is the date to match.

The 'date_format' pattern is a typical C<strptime> pattern. See
L<DateTime::Format::Strptime> for details.

=head1 COPYRIGHT

Copyright (c) 2003 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
