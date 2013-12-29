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
    $code->();
    push @events, [ 'EXIT subtest', $name ];
  }
);

use Test::CPAN::Changes::ReallyStrict::Object;

my $obj = Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    testbuilder         => $mock,
    delete_empty_groups => undef,
    keep_comparing      => undef,
    filename            => "$FindBin::Bin/../corpus/Changes_01.txt"
  }
);

ok( $obj->changes_ok, "Expected good file is good" ) or note explain \@events;

done_testing;
