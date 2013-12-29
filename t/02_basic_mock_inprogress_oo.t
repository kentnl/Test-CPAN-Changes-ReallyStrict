use strict;
use warnings;

use Test::More 0.96;
use Test::MockObject;
use FindBin;

my $mock = Test::MockObject->new();

our @events;

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

use Test::CPAN::Changes::ReallyStrict::Object;

#
# This tests for the behaviour that, a file with a {{NEXT}}
# token in it is deemed "invalid" if the next-token option is
# not parsed to the validator.
#

my $obj = Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    testbuilder         => $mock,
    delete_empty_groups => undef,
    keep_comparing      => undef,
    next_token          => '__',
    filename            => "$FindBin::Bin/../corpus/Changes_02.txt",
  }
);

if ( not ok( !$obj->changes_ok, "Expected bad file is bad ( In progress )" ) ) {
  diag join q[, ], @{$_} for @events;
}

done_testing;
