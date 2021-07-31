#!perl

requires 'perl'                 => '5.014';
requires 'Carp';
requires 'Class::Accessor'      => '0.18';
requires 'Class::Factory'       => '1.00';
requires 'Data::Dumper';
requires 'Data::UUID';
requires 'DBI';
requires 'DateTime'             => '0.15';
requires 'DateTime::Format::Strptime' => '1.00';
requires 'Exception::Class'     => '1.10';
requires 'File::Slurp';
requires 'Log::Log4perl'        => '0.34';
requires 'Module::Runtime';
requires 'Safe';
requires 'Scalar::Util';
requires 'Syntax::Keyword::Try' => '0.25';
requires 'XML::Simple'          => '2.00';


feature examples =>
    ("The example ticketing application" =>
     sub {
         requires 'CGI';
         requires 'CGI::Cookie';
         requires 'DBD::SQLite';
         requires 'HTTP::Daemon';
         requires 'HTTP::Request';
         requires 'HTTP::Response';
         requires 'HTTP::Status';
         requires 'Template';
     });


on test => sub {
    requires 'DBD::Mock'             => '0.10';
    requires 'List::MoreUtils';
    requires 'Mock::MonkeyPatch';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::Exception';
    requires 'Test::Kwalitee'        => '1.21';
    requires 'Test::More'            => '0.88';
    requires 'Test::Pod'             => '1.41';
    requires 'Test::Pod::Coverage'   => '1.08';
    requires 'Test::Without::Module' => '0.20';
};
