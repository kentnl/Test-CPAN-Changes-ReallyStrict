use Test::More;
eval 'use Test::CPAN::Changes::ReallyStrict';
plan skip_all => 'Test::CPAN::Changes::ReallyStrict required for this test' if $@;
$Text::Wrap::columns = 120;
$Text::Wrap::break   = '(?![\x{00a0}\x{202f}])\s';
$Text::Wrap::huge    = 'overflow';
changes_ok();
done_testing();

