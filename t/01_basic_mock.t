use strict;
use warnings;

use Test::More 0.96;
use FindBin;
use lib "$FindBin::Bin/lib";
use mocktest;

my $mock = mocktest->new();

use Test::CPAN::Changes::ReallyStrict;

my $rval = Test::CPAN::Changes::ReallyStrict::_real_changes_file_ok(
  $mock,
  {
    delete_empty_groups => undef,
    keep_comparing      => undef,
    filename            => "$FindBin::Bin/../corpus/Changes_01.txt",
  }
);

if ( not ok( $rval, "Expected good file is good" ) ) {
  note $_ for $mock->ls_events;
}

done_testing;
