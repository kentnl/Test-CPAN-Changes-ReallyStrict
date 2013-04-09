use Test::More;
eval 'use Test::CPAN::Changes::ReallyStrict';
plan skip_all => 'Test::CPAN::Changes::ReallyStrict required for this test' if $@;
changes_ok();
done_testing();

