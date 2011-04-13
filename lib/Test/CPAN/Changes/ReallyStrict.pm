use strict;
use warnings;

package Test::CPAN::Changes::ReallyStrict;

#ABSTRACT: Ensure a Changes file looks exactly like it would if it was machine generated.

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

This is not for the faint of heart, and will whine about even minor changes of whitespace.

You are also at upstreams mercy as to what a changes file looks like, and in order to keep this test
happy, you'll have to update your whole changes file if upstream changes how they format things.

=cut

use CPAN::Changes;
use Test::Builder;

my $test       = Test::Builder->new();
my $version_re = '^[._\-[:alnum:]]+$';    # "Looks like" a version

sub import {
  my $self = shift;

  my $caller = caller;
  {
    no strict 'refs';
    *{ $caller . '::changes_ok' }      = \&changes_ok;
    *{ $caller . '::changes_file_ok' } = \&changes_file_ok;
  }
  $Test->exported_to($caller);
  $Test->plan(@_);
}

sub _config {
  my ($config) = shift;
  if ( not defined $config ) {
    $config = {};
  }
  if ( ( not exists $config->{remove_empty_sections} ) or ( not defined $config->{remove_empty_sections} ) ) {
    $config->{remove_empty_sections} = 0;
  }
  else {

    # force boolean context.
    $config->{remove_empty_sections} = !!$config->{remove_empty_sections};
  }
  return $config;
}

sub changes_file_ok {
  my ( $file, $config ) = @_;
  $file ||= 'Changes';
  my $real_config = _config($config);

  my $changes = eval { CPAN::Changes->load($file) };

  if ($@) {
    $Test->ok( 0, "Unable to parse $file" );
    $Test->diag("  ERR: $@");
    return;
  }

  $Test->ok( 1, "$file is loadable" );

  my @releases = $changes->releases;

  if ( !@releases ) {
    $Test->ok( 0, "$file does not contain any releases" );
    return;
  }

  $Test->ok( 1, "$file contains at least one release" );

  for (@releases) {
    if ( $_->date !~ m{^${CPAN::Changes::W3CDTF_REGEX}\s*$} ) {
      $Test->ok( 0, "$file contains an invalid release date" );
      $Test->diag( '  ERR: ' . $_->date );
      return;
    }
    if ( $_->version !~ m{$version_re} ) {
      $Test->ok( 0, "$file contains an invalid version number" );
      $Test->diag( '  ERR: ' . $_->version );
      return;
    }
  }

  $Test->ok( 1, "$file contains valid release dates" );
  $Test->ok( 1, "$file contains valid version numbers" );

  {

    # linewise test.
    my $fh;

    if ( not open $fh, '<', $file ) {
      $Test->ok( 0, "$file failed to open" );
      $Test->diag("file: $file error:$!");
      return;
    }

    my (@orig) = <$fh>;
    chomp for @orig;

    if ( $real_config->{delete_empty_groups} ) {
      if ( eval { CPAN::Changes->VERSION('0.14'); 1 } ) {
        $changes->delete_empty_groups;
      }
      else {
        $Test->note("delete_empty_groups not available in CPAN::Changes $CPAN::Changes::VERSION");
      }
    }
    my $serialized = $changes->serialize;

    my (@out) = split /\n/, $serialized;

    my $success = 1;

    for ( 0 .. $#out ) {
      if ( $orig[$_] ne $out[$_] ) {
        if ($success) {
          $Test->ok( 0, "Lines differ from standard on line $_ in $file" );
          $Test->diag( 'Expected: >' . $out[$_] . '<<EOL' );
          $Test->diag( 'Got:      >' . $orig[$_] . '<<EOL' );
          $success = 0;
        }
        else {
          $Test->note( $_ . '<> Expected: >' . $out[$_] . '<<EOL' );
          $Test->note( $_ . '<> Got:      >' . $orig[$_] . '<<EOL' );
        }
      }
    }

    if ( scalar @orig != scalar @out ) {
      if ($success) {
        $Test->ok( 0, "Number of lines mismatched" );
        $Test->diag( "Source" . scalar @orig );
        $Test->diag( "Expected" . scalar @out );
        $success = 0;
      }
      else {
        $Test->note("Number of lines mismatched");
        $Test->note( "Source" . scalar @orig );
        $Test->note( "Expected" . scalar @out );

      }
    }

    if ($success) {
      $Test->ok( 1, "Input and output are identical" );
    }
  }

}

1;
