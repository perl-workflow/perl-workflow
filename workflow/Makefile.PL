use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opts = (
    'NAME'	       => 'Workflow',
    'VERSION_FROM' => 'VERSION',
    'PL_FILES'     => {},
    'PREREQ_PM'    => {
      'Class::Accessor'            => 0.18,
      'DateTime'                   => 0.15,
      'DateTime::Format::Strptime' => 1.00,
      'DBD::Mock'                  => 0.10,
      'Exception::Class'           => 1.10,
      'Log::Dispatch'              => 2.00,
      'Log::Log4perl'              => 0.34,
      'Test::More'                 => 0.41,
      'XML::Simple'                => 2.00,
  },
);

if ( $ExtUtils::MakeMaker::VERSION >= 5.43 ) {
    $opts{AUTHOR}   = 'Chris Winters <chris@cwinters.com>';
    $opts{ABSTRACT} = 'Simple but flexible and powerful standalone workflow system';
}

WriteMakefile( %opts );

