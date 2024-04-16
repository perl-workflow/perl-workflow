#!perl

requires 'perl'                 => '5.014';
requires 'parent';
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
requires 'Log::Any'             => '1.050'; # added structural and contextual logging
requires 'Module::Runtime';
requires 'Safe';
requires 'Scalar::Util';
requires 'Syntax::Keyword::Try' => '0.25';
requires 'XML::Simple'          => '2.00';
requires 'YAML'                 => '1.30';
requires 'Readonly';

feature examples =>
    ("The example ticketing application" =>
     sub {
         requires 'DBD::SQLite';
         requires 'DBI';
         requires 'File::Spec::Functions';
         requires 'Getopt::Long';

         # specific for the CGI & web application:
         requires 'CGI';
         requires 'CGI::Cookie';
         requires 'Cwd';
         requires 'HTTP::Daemon';
         requires 'HTTP::Request';
         requires 'HTTP::Response';
         requires 'HTTP::Status';
         requires 'Template';
     });


on test => sub {
    requires 'DBD::Mock'             => '1.59'; # 1.45 is broken; 1.59 is not (and >3yrs old)
    requires 'List::MoreUtils';
    requires 'Mock::MonkeyPatch';
    requires 'Test::Exception';
    requires 'Test::More'            => '0.88';
    requires 'Test::Without::Module' => '0.20';
};

on develop => sub {
    # Note that Dist::Zilla injects its own dependencies for AUTHOR_TESTS
    requires 'Test::Pod::Links'       => '0.003';
};
