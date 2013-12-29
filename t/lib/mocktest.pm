use strict;
use warnings;
use utf8;

package mocktest;

# ABSTRACT: Mock Test::Builder

use Class::Tiny {
  all_events => sub { [] },
  depth      => sub { 0 },
};

sub ok {
  my ( $self, $code, $reason, @extra ) = @_;
  push @{ $self->all_events }, [ 'ok', $code, $reason, @extra ];
  return $code;
}

sub diag {
  my ( $self, @message ) = @_;
  push @{ $self->all_events }, [ 'diag', @message ];
  return 1;
}

sub subtest {
  my ( $self, $desc, $sub ) = @_;

  my $rval;
  push @{ $self->all_events }, [ 'subtest', $desc, 'ENTER', $self->depth ];
  {
    local $self->{depth} = do { $self->{depth} + 1 };
    $rval = $sub->();
  }
  push @{ $self->all_events }, [ 'subtest', $desc, 'EXIT', $self->depth ];
  return $rval;
}

1;

