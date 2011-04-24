
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'Module::Build' => '0.3601',
    'Test::MockObject' => '0',
    'Test::More' => '0.96'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Ensure a Changes file looks exactly like it would if it was machine generated.',
  'dist_author' => [
    'Kent Fredric <kentnl@cpan.org>'
  ],
  'dist_name' => 'Test-CPAN-Changes-ReallyStrict',
  'dist_version' => '0.1.2',
  'license' => 'perl',
  'module_name' => 'Test::CPAN::Changes::ReallyStrict',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'CPAN::Changes' => '0.17',
    'Test::Builder' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
