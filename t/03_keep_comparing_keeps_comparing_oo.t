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
    my $rval;
    push @events, [ 'ENTER subtest', $name ];
    $rval = $code->();
    push @events, [ 'EXIT subtest', $name ];
    return $rval;
  }
);

use Test::CPAN::Changes::ReallyStrict::Object;

my $x = Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    testbuilder         => $mock,
    filename            => "$FindBin::Bin/../corpus/Changes_02.txt",
    delete_empty_groups => undef,
    keep_comparing      => 1,
  }
);

my $diag_needed;

if ( not ok( !$x->changes_ok, "Expected bad file is bad ( In progress )" ) ) {
  $diag_needed = 1;
}
if ( not is( scalar @events, 708, "There is 708 events sent to the test system with this option on" ) ) {
  $diag_needed = 1;
}
if ($diag_needed) {
  for my $event (@events) {
    diag( join q[, ], @$event );
  }
}

done_testing;
