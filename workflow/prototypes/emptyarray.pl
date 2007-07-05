#!/usr/bin/perl -w

use strict;

if (returnArray()) {
	print STDERR "We got an empty array\n";	
	print STDERR "We evaluate to true\n";
} else {
	print STDERR "We got an empty array\n";	
	print STDERR "We evaluate to false\n";
}


sub returnArray {
	return ();
}
