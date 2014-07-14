use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Test::CPAN::Changes::ReallyStrict;

our $VERSION = '1.000001';

#ABSTRACT: Ensure a Changes file looks exactly like it would if it was machine generated.

# AUTHORITY

=head1 SYNOPSIS

  use Test::More;
  eval 'use Test::CPAN::Changes::ReallyStrict';
  plan skip_all => 'Test::CPAN::Changes::ReallyStrict required for this test' if $@;
  changes_ok();
  done_testing();

=cut

=head1 DESCRIPTION

This module is for people who want their Changes file to be 1:1 Identical to how it would be
if they'd generated it programmatically with CPAN::Changes.

This is not for the faint of heart, and will whine about even minor changes of white-space.

You are also at upstream's mercy as to what a changes file looks like, and in order to keep this test
happy, you'll have to update your whole changes file if upstream changes how they format things.

=cut

use CPAN::Changes 0.17;
use Test::Builder;
use Test::CPAN::Changes::ReallyStrict::Object;

my $TEST = Test::Builder->new();

sub import {
  my ( undef, @args ) = @_;

  my $caller = caller;
  {
    ## no critic (ProhibitNoStrict);
    no strict 'refs';
    *{ $caller . '::changes_ok' }      = \&changes_ok;
    *{ $caller . '::changes_file_ok' } = \&changes_file_ok;
  }
  $TEST->exported_to($caller);
  $TEST->plan(@args);
  return 1;
}

=efunc changes_ok

  changes_ok();

  changes_ok({
    delete_empty_groups => 1,
    keep_comparing => 1,
    next_style => 'dzil'
  });

=cut

sub changes_ok {
  my (@args) = @_;
  return changes_file_ok( undef, @args );
}

# For testing.
sub _real_changes_ok {
  my ( $tester, $state ) = @_;
  return _real_changes_file_ok( $tester, $state );
}

=efunc changes_file_ok

  changes_file_ok();

  changes_file_ok('ChangeLog');

  changes_ok('ChangeLog', {
    delete_empty_groups => 1,
    keep_comparing => 1,
    next_style => 'dzil'
  });

=cut

sub changes_file_ok {
  my ( $file, $config ) = @_;
  $file ||= 'Changes';
  $config->{filename} = $file;
  my $changes_obj = Test::CPAN::Changes::ReallyStrict::Object->new(
    {
      testbuilder => $TEST,
      %{$config},
    },
  );
  return $changes_obj->changes_ok;
}

# Factoring design split so testing can inject a test::builder dummy

sub _real_changes_file_ok {
  my ( $tester, $state ) = @_;
  my $changes_obj = Test::CPAN::Changes::ReallyStrict::Object->new(
    {
      testbuilder => $tester,
      %{$state},
    },
  );
  return $changes_obj->changes_ok;
}

1;
