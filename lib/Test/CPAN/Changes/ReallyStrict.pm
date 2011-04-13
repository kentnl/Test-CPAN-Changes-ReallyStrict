use strict;
use warnings;
package Test::CPAN::Changes::ReallyStrict;

#ABSTRACT: Ensure a Changes file looks exactly like it would if it was machine generated.

use Test::More;
eval 'use Test::CPAN::Changes::ReallyStrict';
plan skip_all => 'Test::CPAN::Changes::ReallyStrict required for this test' if $@;
changes_ok();
done_testing();

=head1 DESCRIPTION

This module is for people who want their Changes file to be 1:1 Identical to how it would be
if they'd generated it programmatically with CPAN::Changes.

This is not for the faint of heart, and will whine about even minor changes of whitespace.

You are also at upstreams mercy as to what a changes file looks like, and in order to keep this test
happy, you'll have to update your whole changes file if upstream changes how they format things.

=cut

1;
