use Module::Build;

Module::Build->new(
    dist_author       => 'Chris Winters <chris@cwinters.com>',
    dist_abstract     => 'Simple, flexible system to implement workflows',
    dist_name         => 'Workflow',
    dist_version_from => 'VERSION',
    distribution_type => 'module',
    license           => 'perl',
    requires          => {
      'Class::Accessor'            => 0.18,
      'Class::Factory'             => 1.00,
      'Class::Observable'          => 1.04,
      'DateTime'                   => 0.15,
      'DateTime::Format::Strptime' => 1.00,
      'DBD::Mock'                  => 0.10,
      'Exception::Class'           => 1.10,
      'Log::Dispatch'              => 2.00,
      'Log::Log4perl'              => 0.34,
      'Safe'                       => 0,
      'Test::More'                 => 0.41,
      'XML::Simple'                => 2.00,
    },
    no_index => {
        directory => [ 'eg', 't' ],
    },
    create_makefile_pl => 'traditional',
)->create_build_script();
