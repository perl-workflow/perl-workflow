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
    return unless ( $date_string );

    # already converted!
    if ( ref ( $date_string ) and UNIVERSAL::isa( $date_string, 'DateTime' ) ) {
        return;
    }

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

Workflow::Validator::MatchesDateFormat - Ensure a stringified date matches a given pattern

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

B<NOTE>: If you pass an empty string (or no string) to this validator
it will not throw an error. Why? If you want a value to be defined it
is more appropriate to use the 'is_required' attribute of the input
field to ensure it has a value.

Also, if you pass a L<DateTime> object to the validator it will not
determine whether the date is correct or within a range. As far as it
is concerned its job is done.

=head1 COPYRIGHT

Copyright (c) 2003-2004 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
