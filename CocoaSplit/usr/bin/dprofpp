#!/usr/bin/perl

=for comment

The contents of this script should normally never run!  The perl wrapper
should pick the correct script in /usr/bin by appending the appropriate version.
You can try appending the appropriate perl version number.  See perlmacosx.pod
for more information about multiple version support in Mac OS X.

=cut

use strict;
use Config ();

my @alt = grep {m,^$0\d+\.\d+(?:\.\d+)?$,} glob("$0*");
print STDERR <<"EOF-A";
perl version $Config::Config{version} can't run $0.  Try the alternative(s):

EOF-A
if(scalar(@alt) > 0) {
    for(@alt) {
	my($ver) = /(\d+\.\d+(?:\.\d+)?)/;
	print STDERR "$_ (uses perl $ver)\n";
    }
} else {
	print STDERR "(Error: no alternatives found)\n";
}
die <<'EOF-B';

Run "man perl" for more information about multiple version support in
Mac OS X.
EOF-B
