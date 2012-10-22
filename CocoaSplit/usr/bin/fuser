#!/usr/bin/perl -w
##
# Copyright (c) 2005 Apple Computer, Inc. All rights reserved.
#
# @APPLE_LICENSE_HEADER_START@
# 
# This file contains Original Code and/or Modifications of Original Code
# as defined in and that are subject to the Apple Public Source License
# Version 2.0 (the 'License'). You may not use this file except in
# compliance with the License. Please obtain a copy of the License at
# http://www.opensource.apple.com/apsl/ and read it before using this
# file.
# 
# The Original Code and all software distributed under the License are
# distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
# EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
# INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
# Please see the License for the specific language governing rights and
# limitations under the License.
# 
# @APPLE_LICENSE_HEADER_END@
##

use strict;
use Getopt::Long qw(GetOptions);

sub usage {
  print "fuser: [-cfu] file ...\n",
    "\t-c\tfile is treated as mount point\n",
    "\t-f\tthe report is only for the named files\n",
    "\t-u\tprint username of pid in parenthesis\n";
}

Getopt::Long::config('bundling');
my %o;
unless (GetOptions(\%o, qw(c f u)) && scalar (@ARGV) > 0) {
  usage();
  exit(1);
}

use IO::Handle;
STDERR->autoflush(1);
STDOUT->autoflush(1);

my $exit_value = 0;

my $space = "";
while (scalar (@ARGV)) {
  my $file =  shift @ARGV;
  if (-e $file) {
    my @command; 
    push(@command, q(/usr/sbin/lsof));
    push(@command, q(-F));
    if ($o{u}) {		# Add user name
      push(@command, q(pfL));
    } else {
      push(@command, q(pf));
    }
    push(@command, q(-f)) if ($o{f});
    push(@command, q(--));
    push(@command, $file);
    # This cryptic statement will cause exec(@command) to run in the child,
    # with the output set up correctl and LSOF's input set up correctly.
    open (LSOF, "-|") or exec(@command);
    my @results = <LSOF>;
    chomp(@results);
    # fuser man page is very explicit about stdout/stderr output
    print STDERR $file, qq(: );
    my $username = "";
    foreach (@results) {
      if (/^p(\d+)$/) {
	if ($username) {
	  print STDERR $username;
	  $username = "";
	}
	print $space, $1;
	$space = q( );
      }
      if (/^f(c|r)[wt]d$/) {
	print STDERR "$1" . $username;
	$username = "";
      }
      $username = "(" . $1 . ")" if (/^L(.+)$/);
    } 
    print STDERR $username . qq(\n);
  } else {
    print STDERR "$0: '$file' does not exist\n";
    $exit_value = 1;
  }
}
exit($exit_value);
