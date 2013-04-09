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

#
# This tests for the behaviour that, a file with a {{NEXT}}
# token in it is deemed "invalid" if the next-token option is
# not parsed to the validator.
#
ok(
  !Test::CPAN::Changes::ReallyStrict::_real_changes_file_ok(
    $mock,
    {
      delete_empty_groups => undef,
      keep_comparing      => undef,
      filename            => "$FindBin::Bin/../corpus/Changes_02.txt",
    }
  ),
  "Expected bad file is bad ( In progress"
  )
  or do {
  note explain \@events;
  };

done_testing;
