#!/usr/bin/perl
#
#Converts txt files into docbook.
#
#Usage: txt2db {-o <output file>} <text file>

my($txtfile, $dbfile) = '';

#These keep track of which constructs we're in the middle of
my($level1,
   $level2,
   $level3,
   $orderedlist,
   $listitem,
   $para);

my($line);
my($id, $title);

# read in cmd-line arguments
#
while (1) {
	if($ARGV[0] eq "-o") {
		$dbfile = $ARGV[0];
		shift(@ARGV);
	} elsif($ARGV[0] eq "-h") {
		&usage;
	} else {
		$txtfile = $ARGV[0];
		shift(@ARGV);
	}

	if ($ARGV[0] eq '') {
		last;
	}
}

# abort if no input file given
# 
if($txtfile eq '') {
	print "txt2db: ERROR text file not specified.\n\n";
	&usage();
} elsif( !(-r $txtfile) ) {
	print "txt2db: ERROR cannot read $f ($!)\n\n";
	&usage();
}

if( $dbfile eq '') {
	$txtfile =~ /([^\/]+)\.txt$/i;
	$dbfile = $1 . ".sgml";
}

$buf = '';

&proc_txt($txtfile);

open(DB, "> $dbfile") || die "txt2db: cannot write to $dbfile ($!)\n";
print DB $buf, "\n";
close(DB);

print "txt2db: created $dbfile from $txtfile\n";
exit(0);

# -----------------------------------------------------------

sub usage {
	print "Usage: txt2db {-o <sgml file>} <text file>\n";
	exit(0);
}

sub proc_txt {
	my($f) = @_;

	# read in the text file
	#
	open(TXT, "$f") || die "txt2db: cannot open $f ($!)\n";
	while (<TXT>) {
		$line = $_;
		$line =~ s/\s+$//;
		$line =~ s/^\s+//;

		# blank lines
		if ($line eq '') {
			&closepara;
			next;
		}
		
		if ($line =~ /^=\w/) {
			&close1;
			$level1 = 1;
			&splittitle;
			if ($id eq '') {
				$line = "<sect1><title>$title</title>\n";
			} else {
				$line = "<sect1 id='$id'><title>$title</title>\n";
			}
		} elsif ($line =~ /^==\w/) {
			&close2;
			$level2 = 1;
			&splittitle;
			if ($id eq '') {
				$line = "<sect2><title>$title</title>\n";
			} else {
				$line = "<sect2 id='$id'><title>$title</title>\n";
			}
		} elsif ($line =~ /^===\w/) {
			&close3;
			$level3 = 1;
			&splittitle;
			if ($id eq '') {
				$line = "<sect3><title>$title</title>\n";
			} else {
				$line = "<sect3 id='$id'><title>$title</title>\n";
			}
		} elsif ($line =~ /^#/) {
			if ($orderedlist == 0) {
				$orderedlist = 1;
				$buf .= "\n<orderedlist>\n";
			}
			&closelistitem;
			$listitem = 1;
			$line =~ s/^#//;
			$line =~ s/^/\n<listitem><para>/;
			$para = 1;
		} elsif ($line =~ /^\*/) {
			if ($list == 0) {
				$list = 1;
				$buf .= "\n<simplelist>\n";
			}
			&closelistitem;
			$listitem = 1;
			$line =~ s/^\*//;
			$line =~ s/^/\n<listitem><para>/;
			$para = 1;
		}
		else {
			&closeorderedlist;
			if ( $para == 0 ) {
				$para = 1;
				$line =~ s/^/<para>/;
			} else {
				$line .= " ";
			}
		}

		# links
		# 
		if ($line =~ /\[\[/) {
			$link = $line;
			$link =~ s/^.*\[\[//;
			$link =~ s/\]\].*$//;
			if ( $link =~ /\ /) {
				$linkname = $link;
				$link =~ s/\ .+$//;
				$linkname =~ s/^\S+\ //;
			} else {
				$linkname = $link;
			}
			$line =~ s/\[\[.*\]\]/<ulink url='$link'><citetitle>$linkname<\/citetitle><\/ulink>/;
		}
		$buf .= $line;
	}
	# close nesting
	#
	&close1;
}

sub close1 {
	&close2;
	if ($level1 == 1) {
		$buf .= "</sect1>\n";
		$level1 = 0;
	}
}

sub close2 {
	&close3;
	if ($level2 == 1) {
		$buf .= "</sect2>\n";
		$level2 = 0;
	}
}

sub close3 {
	&closeorderedlist;
	&closelist;
	&closepara;
	if ($level3 == 1) {
		$buf .= "</sect3>\n";
		$level3 = 0;
	}
}

sub closeorderedlist {
	&closepara;
	&closelistitem;
	if ($orderedlist == 1 ) {
		$buf .= "</orderedlist>\n";
		$orderedlist = 0;
	}
}

sub closelist {
	&closepara;
	&closelistitem;
	if ($list == 1 ) {
		$buf .= "</simplelist>\n";
		$list = 0;
	}
}

sub closelistitem {
	&closepara;
	if ($listitem == 1 ) {
		$buf .= "</listitem>\n";
		$listitem = 0;
	}
}

sub closepara {
	if ($para == 1) {
		$buf .= "</para>\n";
		$para = 0;
	}
}

sub splittitle {
	$line =~ s/^=+//;
	$line =~ s/=+$//;
	$title = $line;
	$id = "";
	if ($line =~ /\|/) {
		$title =~ s/\|\w+//;
		$id = $line;
		$id =~ s/^.+\|//;
	}
}
