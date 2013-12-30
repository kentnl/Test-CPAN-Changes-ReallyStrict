use Test::More;
eval 'use Test::CPAN::Changes::ReallyStrict::Object';
plan skip_all => 'Test::CPAN::Changes::ReallyStrict::Object required for this test' if $@;
Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    filename => 'Changes'
  }
)->changes_ok();
done_testing();

