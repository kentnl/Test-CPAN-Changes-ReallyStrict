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
$mock->mock(
  'subtest' => sub {
    my ( $self, $name, $code ) = @_;
    push @events, [ 'ENTER subtest', $name ];
    my $rval = $code->();
    push @events, [ 'EXIT subtest', $name ];
    return $rval;
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
use Test::CPAN::Changes::ReallyStrict::Object;

my $obj = Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    testbuilder         => $mock,
    filename            => "$FindBin::Bin/../corpus/Changes_03.txt",
    delete_empty_groups => undef,
    keep_comparing      => 1,
    next_token          => qr/{{\$NEXT}}/
  }
);

my $need_diag;

if ( not ok( $obj->changes_ok, "Expected {NEXT} file is good ( Fixed in CPAN::Changes 0.17 )" ) ) {
  $need_diag = 1;
}
if ( not is( scalar @events, 423, 'There are 423 events sent to the test system with this option on' ) ) {
  $need_diag = 1;
}
if ($need_diag) {
  for my $event (@events) {
    diag( join q[, ], @$event );
  }
}
done_testing;
