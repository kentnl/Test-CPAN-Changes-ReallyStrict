use Test::More;
use CPAN::Changes;

eval 'use Test::CPAN::Changes::ReallyStrict';
plan skip_all => 'Test::CPAN::Changes::ReallyStrict required for this test' if $@;

local $Test::CPAN::Changes::ReallyStrict::Object::TODO;

if ( eval 'CPAN::Changes->VERSION(q[0.5]); 1' ) {
  if ( not $ENV{AUTHOR_TESTING} ) {
    $Test::CPAN::Changes::ReallyStrict::Object::TODO = "CPAN::Changes >= 0.5 is too new for this test";
  }
}

$Text::Wrap::columns = 120;
$Text::Wrap::break   = '(?![\x{00a0}\x{202f}])\s';
$Text::Wrap::huge    = 'overflow';
changes_ok();
done_testing();

