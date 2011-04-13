use strict;
use warnings;

package Test::CPAN::Changes::ReallyStrict;
BEGIN {
  $Test::CPAN::Changes::ReallyStrict::VERSION = '0.1.0';
}

#ABSTRACT: Ensure a Changes file looks exactly like it would if it was machine generated.



use CPAN::Changes;
use Test::Builder;

my $TEST       = Test::Builder->new();
my $version_re = '^[._\-[:alnum:]]+$';    # "Looks like" a version

sub import {
  my ( $self, @args ) = @_;

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

sub _config {
  my ($config) = shift;
  if ( not defined $config ) {
    $config = {};
  }

  # force boolean context.
  $config->{delete_empty_groups} = !!$config->{delete_empty_groups};
  $config->{keep_comparing}      = !!$config->{keep_comparing};
  if ( defined $config->{next_style} and $config->{next_style} = 'dzil' ) {
    $config->{next_token} = qr/{{\$NEXT}}/;
  }

  return $config;
}


sub changes_ok {
  my (@args) = @_;
  $TEST->plan( tests => 4 );
  return changes_file_ok( undef, @args );
}

# For testing.
sub _real_changes_ok {
  my ( $tester, $state ) = @_;
  $tester->plan( tests => 4 );
  return _real_changes_file_ok( $tester, $state );
}


sub changes_file_ok {
  my ( $file, $config ) = @_;
  $file ||= 'Changes';
  my $real_config = _config($config);
  $real_config->{filename} = $file;
  return _real_changes_file_ok( $TEST, $real_config );
}

# Factoring design split so testing can inject a test::builder dummy

sub _real_changes_file_ok {
  my ( $tester, $state ) = @_;

  #die q{Internal error, filename should be defined} if ( not defined $state->{filename} );
  return unless _test_load( $tester, $state );
  return unless _test_has_releases( $tester, $state );
  return unless _test_releases( $tester, $state );
  return unless _stash_original_content( $tester, $state );
  return unless _prune( $tester, $state );
  return unless _stash_serialized_content( $tester, $state );
  return unless _test_lines( $tester, $state );
  return 1;
}

sub _test_load {
  my ( $tester, $state ) = @_;

  my @extra;
  if ( defined $state->{next_token} ) {
    @extra = ( next_token => $state->{next_token} );
  }
  my ( $error, $changes, $success );
  {
    ## no critic ( ProhibitPunctuationVars )
    local $@ = undef;

    $success = eval { $changes = CPAN::Changes->load( $state->{filename}, @extra ); 1 };
    $error = $@;
  }

  if ( not $error and $success ) {
    $tester->ok( 1, $state->{filename} . ' is loadable' );
    $state->{changes} = $changes;
    return 1;
  }

  $tester->ok( 0, 'Unable to parse ' . $state->{filename} );
  $tester->diag($error);
  return;
}

sub _test_has_releases {
  my ( $tester, $state ) = @_;

  # dump [ '_test_has_releases' , $tester, $state ];
  my (@releases) = $state->{changes}->releases;
  if (@releases) {
    $tester->ok( 1, $state->{filename} . ' contains at least one release' );
    return 1;
  }
  $tester->ok( 0, $state->{filename} . ' does not contain any release' );
  return;
}

sub _test_release_date {
  my ( $tester, $state ) = @_;
  return 1 if not defined $state->{release}->date and defined $state->{next_token};
  return 1 if $state->{release}->date =~ m/^${CPAN::Changes::W3CDTF_REGEX}\s*$/;
  $tester->ok( 0, $state->{file} . ' contains an invalid release date' );
  $tester->diag( '  ERR: ' . $state->{release}->date );
  return;
}

sub _test_release_version {
  my ( $tester, $state ) = @_;
  return 1 if not defined $state->{release}->version and defined $state->{next_token};
  return 1 if defined $state->{next_token} and $state->{release}->version =~ $state->{next_token};
  return 1 if ( $state->{release}->version =~ m/$version_re/ );
  $tester->ok( 0, $state->{filename} . ' contains an invalid release version number' );
  $tester->diag( '  ERR: ' . $state->{release}->version );
  return;
}

sub _test_releases {
  my ( $tester, $state ) = @_;
  for ( $state->{changes}->releases ) {
    ## no critic ( ProhibitLocalVars)
    local $state->{release} = $_;
    return unless _test_release_date( $tester, $state );
    return unless _test_release_version( $tester, $state );
  }
  $tester->ok( 1, $state->{filename} . ' contains valid release dates' );
  $tester->ok( 1, $state->{filename} . ' contains valid version numbers' );
  return 1;
}

sub _stash_original_content {
  my ( $tester, $state ) = @_;
  ## no critic (ProhibitPunctuationVars)

  my $fh;
  if ( not open $fh, '<', $state->{filename} ) {
    $tester->ok( 0, $state->{filename} . ' failed to open' );
    $tester->diag( 'Error ' . $! );
    return;
  }
  my $str = do {
    local $/ = undef;
    scalar <$fh>;
  };
  close $fh or $tester->diag( 'Warning: Error Closing ' . $state->{filename} );

  my @lines = split /\n/, $str;

  $state->{original_lines} = \@lines;
  return 1;
}

sub _prune {
  my ( $tester, $state ) = @_;
  return 1 unless $state->{delete_empty_groups};

  my ( $rval, $error );

  {
    ## no critic ( ProhibitPunctuationVars )

    local $@ = undef;
    $rval = eval { CPAN::Changes->VERSION('0.14'); 1 };
    $error = $@;
  }

  if ( $error or not $rval ) {
    $tester->ok( 0, 'delete_empty_groups not supported on CPAN::Changes prior to 0.14' );
    $tester->diag("CPAN::Changes Version: $CPAN::Changes::VERSION");
    return;
  }

  $state->{changes}->delete_empty_groups();

  return 1;
}

sub _stash_serialized_content {
  my ( $tester, $state ) = @_;

  my $string = $state->{changes}->serialize;

  my (@out) = split /\n/, $string;

  $state->{generated_lines} = \@out;

  return 1;

}

sub _test_line {
  my ( $tester, $state ) = @_;
  return 1
    if defined $state->{line}->{original}
      and defined $state->{line}->{generated}
      and $state->{line}->{original} eq $state->{line}->{generated};
  if ( not $state->{had_first_line_failure} ) {
    $tester->ok( 0, 'Lines differ at line ' . $state->{line}->{no} );
    $state->{had_first_line_failure} = 1;
  }
  $tester->diag( '['
      . $state->{line}->{no}
      . '] Expected: '
      . ( defined $state->{line}->{generated} ? '>' . $state->{line}->{generated} . '<' : 'not defined' ) );
  $tester->diag( '['
      . $state->{line}->{no}
      . '] Got     : '
      . ( defined $state->{line}->{original} ? '>' . $state->{line}->{original} . '<' : 'not defined' ) );
  return;
}

sub _test_lines {
  my ( $tester, $state ) = @_;

  my (@original)  = @{ $state->{original_lines} };
  my (@generated) = @{ $state->{generated_lines} };

  for ( 0 .. $#original ) {
    ## no critic ( ProhibitLocalVars )
    local $state->{line} = { original => $original[$_], generated => $generated[$_], no => $_ };
    return if not _test_line( $tester, $state ) and not $state->{keep_comparing};
  }
  if ( $state->{keep_comparing} and not $state->{had_first_line_failure} ) {
    $tester->ok( 1, 'All lines in original match generated' );
    return 1;
  }

  if ( not $state->{keep_comparing} ) {
    return 1;
  }
  return;
}

1;

__END__
=pod

=head1 NAME

Test::CPAN::Changes::ReallyStrict - Ensure a Changes file looks exactly like it would if it was machine generated.

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

  use Test::More;
  eval 'use Test::CPAN::Changes::ReallyStrict';
  plan skip_all => 'Test::CPAN::Changes::ReallyStrict required for this test' if $@;
  changes_ok();
  done_testing();

=head1 DESCRIPTION

This module is for people who want their Changes file to be 1:1 Identical to how it would be
if they'd generated it programmatically with CPAN::Changes.

This is not for the faint of heart, and will whine about even minor changes of white-space.

You are also at upstreams mercy as to what a changes file looks like, and in order to keep this test
happy, you'll have to update your whole changes file if upstream changes how they format things.

=head1 EXPORTED FUNCTIONS

=head2 changes_ok

  changes_ok();

  changes_ok({
    delete_empty_groups => 1,
    keep_comparing => 1,
    next_style => 'dzil'
  });

=head2 changes_file_ok

  changes_file_ok();

  changes_file_ok('ChangeLog');

  changes_ok('ChangeLog', {
    delete_empty_groups => 1,
    keep_comparing => 1,
    next_style => 'dzil'
  });

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

