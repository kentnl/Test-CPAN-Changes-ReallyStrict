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

use Test::CPAN::Changes::ReallyStrict;

ok(
  Test::CPAN::Changes::ReallyStrict::_real_changes_file_ok(
    $mock,
    {
      delete_empty_groups => undef,
      keep_comparing      => undef,
      filename            => "$FindBin::Bin/../corpus/Changes_01.txt",
    }
  ),
  "Expected good file is good"
  )
  or do {
  note explain \@events;
  };

done_testing;
