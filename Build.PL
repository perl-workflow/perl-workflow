#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

# $Id$

Module::Build->new(
    dist_author       => 'Jonas B. NIelsen <jonasbn@cpan.org>',
    dist_abstract     => 'Simple, flexible system to implement workflows',
    dist_name         => 'Workflow',
    dist_version_from => 'lib/Workflow.pm',
    distribution_type => 'module',
    license           => 'perl',
    configure_requires => {
        'Module::Build' => '0.40',
    },
    test_requires    => {
        'DBD::Mock'       => '0.10',
        'List::MoreUtils' => '0',
        'Test::More'      => '0.41',
        'Test::Exception' => '0',
    },
    requires          => {
      'Class::Accessor'            => '0.18',
      'Class::Factory'             => '1.00',
      'Class::Observable'          => '1.04',
      'DateTime'                   => '0.15',
      'DateTime::Format::Strptime' => '1.00',
      'Exception::Class'           => '1.10',
      'Log::Dispatch'              => '2.00',
      'Log::Log4perl'              => '0.34',
      'Safe'                       => '0',
      'XML::Simple'                => '2.00',
      'DBI'                        => '0',
      'Data::Dumper'               => '0',
      'Carp'                       => '0',
      'File::Slurp'                => '0',
      'perl'                       => '5.6.0',
    },
    recommends => {
        'SPOPS'      => '0',
        'Data::UUID' => '0',
      },
    add_to_cleanup  => [qw(
      MANIFEST 
      MANIFEST.bak 
      *.gz 
      MYMETA.* 
      META.* 
      t/db 
      t/workflow_tests.log
    )],
    no_index => {
        directory => [ 'eg', 't' ],
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    meta_merge => {
        resources => {
            homepage   => 'https://github.com/jonasbn/perl-workflow',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Workflow',
            repository => 'https://github.com/jonasbn/perl-workflow',
        }
    },
)->create_build_script();

exit 0;
