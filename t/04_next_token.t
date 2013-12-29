use strict;
use warnings;

use Test::More 0.96;
use Test::MockObject;
use FindBin;

my $mock = Test::MockObject->new();

my @events;

$mock->mock(
  'ok' => sub {
    my ( $self, @args ) = @_;
    push @events, [ 'ok', @args ];
  }
);

$mock->mock(
  'diag' => sub {
    my ( $self, @args ) = @_;
    push @events, [ 'diag', @args ];
  }
);

#
# This test tests the behaviour of Changes files with {{$NEXT}} in them.
# Prior to CPAN::Changes 0.17, CPAN::Changes emitted extra whitespace.
#
# This tests for this behaviour being sufficient to cause a problem.
#
# However, as of 0.17 it is no longer a problem, but this test is still
# here in case other inconsitencies crop up.
#
use Test::CPAN::Changes::ReallyStrict;

ok(
  Test::CPAN::Changes::ReallyStrict::_real_changes_file_ok(
    $mock,
    {
      delete_empty_groups => undef,
      keep_comparing      => 1,
      filename            => "$FindBin::Bin/../corpus/Changes_03.txt",
      next_token          => qr/{{\$NEXT}}/
    }
  ),
  "Expected {NEXT} file is good ( Fixed in CPAN::Changes 0.17 )"
  )
  or do {
  note explain \@events;
  };

is( scalar @events, 5, 'There are 5 events sent to the test system with this option on' ) or note explain \@events;

done_testing;
