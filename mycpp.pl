use Cwd;
use Defines;

if ($#ARGV<0){
	# printf "usage: perl mycpp.pl <file>\n";
	exit(0);
}

my $the_glob=$ARGV[0];
#print "$pat $the_glob\n";
$SIG{'INT'} = 'handler';
my $dir = Cwd::getcwd();
# my $dir = `cd`;
# chomp($dir);
chdir($dir);
my $commentDir = 'comment';
my $decommentDir = 'decomment';
my $deifdefDir = 'deifdef';
my $structDir = 'structs';
# my $de = '\s|{|}|,|;|\(|\)';
my $mydefs = Defines->new();
# print $mydefs{HAVE_SSE2}."\n";
# print $mydefs->{HAVE_SSE2}."\n";
# foreach $key (keys %$mydefs) {
#   $value = $mydefs->{$key};
#   print "  $key costs $value\n";
# }
my $debugprint = 0;
my @file_list;
my @tmpAry = split('/', $the_glob);
if ($#tmpAry>-1){
	$dir .= '/'.join('/', @tmpAry[0..$#tmpAry-1]);
}
my @file_list = glob($the_glob);
# print "debug1:$the_glob : $dir : ".join(' ', @file_list)."\n";
foreach my $file (@file_list){
	@tmpAry = split('/', $file);
	my $file2 = $file;
	if ($#tmpAry > -1){
		$file2 = $tmpAry[-1];
	}
	# print "debug1:$file $file2\n";
	print "processing... decomment $file\n";
	decomment($file, $file2, $dir, $decommentDir, $commentDir);
	print "processing... deifdef $file2\n";
	procifdef($file, $file2, $decommentDir, $deifdefDir);
	print "processing... extractStruct $file2\n";
	extractStruct($file, $file2, $deifdefDir, $structDir);
	print "\n";
}

#---
# todo
sub extractFunction {

}

sub printoutstr {
	my $ofp = shift;
	my $poutstr = shift;
	my @outstr = @$poutstr;
	my $tmpstr = '';
	# print "debug:6-0:printoutstr\n";
	foreach my $str (@outstr){
		# if ($str =~ /^\n$/) {
		# 	next;
		# }
		$tmpstr .= $str;
	}
	$tmpstr =~ s/\n\{/ \{/go;
	$tmpstr =~ s/\{([^\n])/\{\n$1/go;
	$tmpstr =~ s/\}([^\s])/\} $1/go;
	$tmpstr =~ s/;([^\n])/;\n$1/go;
	$tmpstr =~ s/\n\s/\n\t/go;
	$tmpstr =~ s/\n\t}/\n\}/go;
	if ($tmpstr =~ /(typedef|struct|union|enum)/){
		print $ofp $tmpstr."\n";
	}
	# print "debug:6-z:printoutstr\n";
}

# todo
sub extractStruct {
	my ($file, $file2, $fromdir, $distdir) = @_;
	if (!(-e $distdir)){
		unless(mkdir $distdir) {
			die "Unable to create $distdir\n";
		}
	}
	open(fp, "<$fromdir/$file2") or die "can not open $fromdir/$file2.";
	open(ofp, ">$distdir/$file2");
	my $linenum = 0;
	my @stack = ();
	my @outstr = ();
	my $status = 1;
	my $preStatus = 0;
	my $tline = '';
	my @inwds = ();
	my $within = 0;
	my $kw1 = 'struct|union|enum';
	my $kw2 = 'typedef';
	my $de = '\s|\n|;|#|{|}|\(|\)|$kw1|$kw2';
	my $oldtypename = '';
	my $newtypename = '';
	# my $debugprint = 1;
	@inwds = nextToken(fp, $de);
	while ($#inwds > -1) {
		# print "debug5-0:$#inwds\n";
		foreach my $wd (@inwds) {
			# if ($wd =~ /^\s*$/) {
			# 	next;
			# }
			# print "debug5-a:$status:$within:$#outstr:$wd\n";
			$linenum++;
			if ($status == -3){
				if ($wd =~ /\)/) {
					pop @stack;
					if ($#stack == -1){
						$status = 1;
					}
				}
			}
			elsif ($status == -2){
				if ($wd =~ /\n/) {
					$status = 1;
				}
			}
			elsif ($status == -1){
				if ($wd =~ /}/) {
					pop @stack;
					if ($#stack == -1){
						$status = 1;
					}
				}
			}
			elsif ($status == 1){
				if ($wd =~ /#/) {
					$status = -2;
				}
				elsif ($wd =~ /{/) {
					$status = -1;
					push @stack, $linenum;
				}
				elsif ($wd =~ /\(/) {
					$status = -3;
					push @stack, $linenum;
				}
				elsif ($wd =~ /$kw2/){
					$status = 2;
					@outstr = ();
					push @outstr, $wd;
				}
				elsif ($wd =~ /$kw1/){
					$status = 3;
					@outstr = ();
					push @outstr, $wd;
				}
				elsif ($wd =~ /;/){
					$status = 1;
					if ($within == 1){
						push @outstr, $wd;
						printoutstr(ofp, \@outstr);
					}
					@outstr = ();
					$within = 0;
				}
			}
			elsif ($status == 2){
				# print "debug5-b:$status:$within:$#outstr:$wd\n";
				# typedef
				push @outstr, $wd;
				$oldtypename = $wd;
				if ($wd =~ /$kw1/){
					$preStatus = 2;
					$status = 3;
				}
				elsif ($wd =~ /;/){
					$status = 1;
					# if ($within == 1){
						printoutstr(ofp, \@outstr);
					# }
					@outstr = ();
					@inwds = ();
					$within = 0;
				}
				else{
					# push @outstr, $wd;
				}
			}
			elsif ($status == 3){
				# stuct
				push @outstr, $wd;
				if ($wd =~ /;/){
					$status = 1;
					# print "debug5-2.1:$status:$within:$#outstr:$wd\n";
					if ($within == 1){
						printoutstr(ofp, \@outstr);
						if ($preStatus == 4){
							$newtypename = $wd;
							$newtypename =~ s/;//;
						}
					}
					else{
						printoutstr(ofp, \@outstr);
					}
					@outstr = ();
					@inwds = ();
					$within = 0;
				}
				elsif ($wd =~ /{/){
					$status = 4;
					$within = 1;
					if ($preStatus == 2){
						$oldtypename .= ' '.$wd;
						$oldtypename =~ s/\{//;
					}
					push @outstr, "\n";
					push @stack, $linenum;
				}
				elsif ($wd =~ /\(|\)/) {
					$status = 1;
					@outstr = ();
					@inwds = ();
					$within = 0;
				}
				else{
					# if ($preStatus == 2){
					# 	$oldtypename .= ' '.$wd;
					# }
					# elsif ($preStatus == 4){
					# 	$newtypename = $wd;
					# }
				}
			}
			elsif ($status == 4){
				push @outstr, $wd;
				if ($wd =~ /{/){
					push @stack, $linenum;
				}
				elsif ($wd =~ /}/){
					pop @stack;
					if ($#stack == -1){
						$preStatus = 4;
						$status = 3;
					}
				}
				elsif ($wd =~ /;/){
					push @outstr, "\n";
				}
				elsif ($wd =~ /$kw2/){
				}
			}
		}
		@inwds = nextToken(fp, $de);
	}
	# if ($tline ne ''){
	# 	print ofp $tline;
	# }
	close(ofp);
	close(fp);
}

sub reversePolishNotation {
	my $conditions = shift;
	my @result = ();
	my @rpnstack = ();
	# $de = '!|\s|\(|\)|>|<|=';
	# print "debug4-1:$conditions\n";
	$conditions =~ s/defined\((.+?)\)/$1/go;
	$conditions =~ s/\s+//go;
	# print "debug4-2:$conditions\n";
	my @inwds = lexer($conditions, '!|\s|\(|\)|>|<|=|\+|\*|&&|\|\|');
	for (my $i=0; $i<=$#inwds; $i++){
		if ($inwds[$i] =~ /^\s+$/){
			next;
		}
		# print "debug4-3:$inwds[$i]:$#result\n";
		if ($inwds[$i] eq '&&' || $inwds[$i] eq '*'){
			push @rpnstack, \$inwds[$i];
		}
		elsif ($inwds[$i] eq '||' || $inwds[$i] eq '+'){
			while ($#rpnstack >-1 && $$rpnstack[$#rpnstack] eq '*') {
				my $op = pop @rpnstack;
				push @result, $op;
			}
			push @rpnstack, \$inwds[$i];
		}
		elsif ($inwds[$i] eq '!' || $inwds[$i] eq '('){
			push @rpnstack, \$inwds[$i];
		}
		elsif ($inwds[$i] eq '>' || $inwds[$i] eq '<' || $inwds[$i] eq '='){
			# while ($#rpnstack >-1 && ($rpnstack[$#rpnstack] eq '*' || $rpnstack[$#rpnstack] eq '+')) {
			# 	$result .= pop @rpnstack;
			# }
			if ($inwds[$i+1] eq '='){
				push @rpnstack, \"$inwds[$i]$inwds[$i+1]";
				$i++;
			}
			else{
				push @rpnstack, \$inwds[$i];
			}
		}
		elsif ($inwds[$i] eq ')'){
			my $op;
			do {
				$op = pop @rpnstack;
				if ($$op ne '('){
					push @result, $op;
				}
			} while ($$op ne '('); #  && $#rpnstack > -1
		}
		else{
			my $digit;
			# print "debug4-4:$inwds[$i] => $mydefs->{$inwds[$i]}\n";
			if ($inwds[$i] =~ /^(\d+)$/){
				$digit = $1;
			}
			elsif (defined($mydefs->{$inwds[$i]})){
				$digit = $mydefs->{$inwds[$i]};
			}
			else{
				$digit = 0;
			}
			# print "debug4-4a:\nrpnstack";
			# foreach my $ch (@rpnstack){
			# 	print ":$$ch";
			# }
			# print "\nresult  ";

			push @result, \$digit;
			if (${$rpnstack[$#rpnstack]} eq '!') {
				my $op = pop @rpnstack;
				push @result, $op;
			}

			# foreach my $ch (@result){
			# 	print ":$$ch";
			# }
			# print "\n";
		}
	}
	while ($#rpnstack > -1) {
		my $op = pop @rpnstack;
		push @result, $op;
	}
	return @result;
}

sub parsecondition {
	my $conditions = shift;
	my @stack2 = ();
	# print "debug3-1:$conditions\n";
	my @RPN = reversePolishNotation($conditions);
	# print "debug3-2:\n";
	# foreach my $ch (@RPN){
	# 	print ":$$ch";
	# }
	# print "\n";
	foreach my $ch (@RPN) {
		if ($$ch eq '*'){
			my $x2 = pop @stack2;
			my $x1 = pop @stack2;
			my $tmp = ($$x1 * $$x2);
			push @stack2, \$tmp;
		}
		elsif ($$ch eq '&&'){
			my $x2 = pop @stack2;
			my $x1 = pop @stack2;
			my $tmp = ($$x1 && $$x2) ? 1 : 0;
			# print "$$x1 && $$x2 : $tmp\n";
			push @stack2, \$tmp;
		}
		elsif ($$ch eq '+'){
			my $x2 = pop @stack2;
			my $x1 = pop @stack2;
			my $tmp = ($$x1 + $$x2);
			push @stack2, \$tmp;
		}
		elsif ($$ch eq '||'){
			my $x2 = pop @stack2;
			my $x1 = pop @stack2;
			my $tmp = ($$x1 || $$x2) ? 1 : 0;
			push @stack2, \$tmp;
		}
		elsif ($$ch eq '>'){
			my $x2 = pop @stack2;
			my $x1 = pop @stack2;
			my $tmp = ($$x1 > $$x2) ? 1 : 0;
			push @stack2, \$tmp;
		}
		elsif ($$ch eq '<'){
			my $x2 = pop @stack2;
			my $x1 = pop @stack2;
			my $tmp = ($$x1 < $$x2) ? 1 : 0;
			push @stack2, \$tmp;
		}
		elsif ($$ch eq '=' || $$ch eq '=='){
			my $x2 = pop @stack2;
			my $x1 = pop @stack2;
			my $tmp = ($$x1 == $$x2) ? 1 : 0;
			push @stack2, \$tmp;
		}
		elsif ($$ch eq '>='){
			my $x2 = pop @stack2;
			my $x1 = pop @stack2;
			my $tmp = ($$x1 >= $$x2) ? 1 : 0;
			# print "$$x1 >= $$x2 : $tmp\n";
			push @stack2, \$tmp;
		}
		elsif ($$ch eq '<='){
			my $x2 = pop @stack2;
			my $x1 = pop @stack2;
			my $tmp = ($$x1 <= $$x2) ? 1 : 0;
			push @stack2, \$tmp;
		}
		elsif ($$ch eq '!'){
			my $x2 = pop @stack2;
			my $tmp = ($$x2 == 0) ? 1 : 0;
			push @stack2, \$tmp;
		}
		else{
			push @stack2, $ch;
		}
	}
	my $val = pop @stack2;
	# print "debug3-3:$#stack2:$$val\n";
	return ($$val == 0) ? 0 : 1;
}

sub procifdef {
	my ($file, $file2, $fromdir, $distdir) = @_;
	if (!(-e $distdir)){
		unless(mkdir $distdir) {
			die "Unable to create $distdir\n";
		}
	}
	open(fp, "<$fromdir/$file2") or die "can not open $fromdir/$file2.";
	open(ofp, ">$distdir/$file2");
	my @conditions = ();
	my @condstrs = ();
	my @inwds = ();
	my @outstr = ();
	my $status = 0;
	my $linenum = 0;
	my $curcond = 1;
	my $curcondstr = '';
	my $kw1 = '\s*#\s*if';
	my $kw2 = '\s*#\s*else';
	my $kw3 = '\s*#\s*endif';
	my $kw4 = '\s*#\s*define';
	my $kw5 = '\s*#\s*elif';
	# $de = '\s';
	# binmode fp, ':encoding(utf8)';
	# binmode fp;
	while(<fp>){
		$linenum++;
		#if ($_ =~ //){
		#	if ($debugprint == 0){
		#		# print "debug start---------\n";
				$debugprint = 1;
		#		$dbsline = $linenum;
		#	}
		#}
		#else{
		#	if ($dbsline-$linenum>30){
		#		$debugprint = 0;
		#	}
		#}
		$_ =~ s/ifdef\s+(.+)/if defined($1)/g;
		$_ =~ s/ifndef\s+(.+)/if !defined($1)/g;
		if ($_ =~ /^\s*$/){
			next;
		}
		if ($contline == 1){
			$tline .= $_;
			$tline =~ s/\\$//go;
		}
		else{
			$tline = $_;
			$tline =~ s/\\$//go;
		}
		if ($_ =~ /\\$/){
			$contline = 1;
			next;
		}
		else{
			$contline = 0;
		}
		$tline =~ s/\n/ /go;
		$tline =~ s/\s+/ /go;
		$tline =~ s/ $//;
		# print "debug2-1 all:$status:$curcond:$curcondstr:$#conditions=>".join(' ', @conditions).":$tline\n" if ($debugprint == 1);
		if ($tline =~ /($kw1|$kw2|$kw3|$kw5)/){
			$wd = $tline;
			# print "debug2-2start:$status:$curcond:$curcondstr:$#conditions=>".join(' ', @conditions).":$wd\n" if ($debugprint == 1);
			if ($status == 0){
				if ($wd =~ /^($kw1)\s+(.+)$/){
					$status = 1;
					push @conditions, $curcond;
					push @condstrs, $curcondstr;
					$curcondstr = $2;
					$curcond = parsecondition($curcondstr);
				}
				else{
					if ($wd !~ /^($kw3)$/){
						push @outstr, $wd;
					}
				}
			}
			elsif ($status == 1){
				if ($wd =~ /^($kw1)\s+(.+)$/){
					push @conditions, $curcond;
					push @condstrs, $curcondstr;
					$curcondstr = $2;
					$curcond = parsecondition($curcondstr);
					$status = 2;
					# print "debug2-3a:1->2:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$wd\n" if ($debugprint == 1);
				}
				elsif ($wd =~ /^($kw2)$/){
					$curcond = 1 - $curcond;
					# print "debug2-3b:$status:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$wd\n" if ($debugprint == 1);
				}
				elsif ($wd =~ /^($kw3)$/){
					$curcond = pop @conditions;
					$curcondstr = pop @condstrs;
					if ($#conditions == -1){
						$status = 0;
						$curcond = 1;
						$curcondstr = '';
						# print "debug2-3c:1->0:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$wd\n" if ($debugprint == 1);
					}
				}
				elsif ($wd =~ /^($kw5)\s+(.+)$/){
					$curcondstr = $2;
					$curcond = parsecondition($curcondstr);
					# $status = 2;
				}
				else{
					if ($curcond == 1){
						push @outstr, $wd;
					}
				}
			}
			elsif ($status == 2){
				if ($wd =~ /^($kw1)\s+(.+)$/){
					push @conditions, $curcond;
					push @condstrs, $curcondstr;
					$curcondstr = $2;
					$curcond = parsecondition($curcondstr);
				}
				elsif ($wd =~ /^($kw2)$/){
					# $curcond = pop @conditions;
					# $curcondstr = pop @condstrs;
					$curcond = 1 - $curcond;
					# push @conditions, $curcond;
					# push @condstrs, $curcondstr;
					# print "debug2-3d:$status:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$wd\n" if ($debugprint == 1);
				}
				elsif ($wd =~ /^($kw3)$/){
					$curcond = pop @conditions;
					$curcondstr = pop @condstrs;
					# print "debug2-3e:$status:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$wd\n" if ($debugprint == 1);
					if ($#conditions == 0){
						$status = 1;
						# print "debug2-3f:2->1:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$wd\n" if ($debugprint == 1);
					}
				}
				elsif ($wd =~ /^($kw5)\s+(.+)$/){
					$curcondstr = $2;
					$curcond = parsecondition($curcondstr);
				}
				else{
					if ($curcond > 0){
						my $hit = 1;
						for (my $i=0; $i<=$#conditions; $i++){
							if ($conditions[$i]==0){
								$hit = 0;
								last;
							}
						}
						if ($hit == 1){
							if ($tline =~ /($kw4)\s+(.+)\s*(.*)/){
								if ($2 ne ''){
									$mydefs->{$1} = $2;
								}
								else{
									$mydefs->{$1} = 1;
								}
							}
							push @outstr, $wd;
						}
					}
				}
			}
		}
		else{
			# print "debug2-5a:$status:$curcond:$curcondstr:$#conditions=>".join(' ', @conditions).":$tline\n" if ($debugprint == 1);
			if ($curcond > 0){
				my $hit = 1;
				for (my $i=0; $i<=$#conditions; $i++){
					if ($conditions[$i]==0){
						$hit = 0;
						last;
					}
				}
				if ($hit == 1){
					if ($tline =~ /($kw4)\s+(.+)\s*(.*)/){
						if ($2 ne ''){
							$mydefs->{$1} = $2;
						}
						else{
							$mydefs->{$1} = 1;
						}
					}
					# print "debug2-5b:$status:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$tline\n" if ($debugprint == 1);
					print ofp "$tline\n";
				}
			}
		}

		if ($#outstr > -1){
			print ofp join(' ', @outstr)."\n";
			@outstr = ();
			@inwds = ();
		}
	}
	close(ofp);
	close(fp);
}

sub decomment {
	my ($file, $file2, $fromdir, $distdir, $comdistDir) = @_;
	if (!(-e $distdir)){
		unless(mkdir $distdir) {
			die "Unable to create $distdir\n";
		}
	}
	if (!(-e $comdistDir)){
		unless(mkdir $comdistDir) {
			die "Unable to create $comdistDir\n";
		}
	}
	open(fp, "<$fromdir/$file2") or die "can not open $fromdir/$file2.";
	open(ofp, ">$distdir/$file2");
	open(ofp2, ">$comdistDir/$file2");
	my $kws = '\/\*';
	my $kwe = '\*\/';
	my $kws2 = '\/\/';
	my $kwdq = '"';
	my $kwq = "'";
	my @inwds = ();
	my @outstr = ();
	my @commentStr = ();
	my $status = 0;
	my $linenum = 0;
	my @inwds = ();
	my $tmp = '';
	my $de = "\\s|;|$kwq|$kwdq|$kws|$kws2|$kwe";
	# my $debugprint = 1;
	@inwds = nextToken(fp, $de);
	while ($#inwds > -1){
		foreach my $wd (@inwds) {
			# print "debug0-2start:$status:$#outstr:$#commentStr:$wd\n" if ($debugprint == 1);
			if ($status == 0){
				if ($wd =~ /($kws)/){
					if ($#outstr > -1){
						$tmp = join('', @outstr);
						# $tmp =~ s/;/;\n/go;
						$tmp =~ s/\n+/\n/go;
						print ofp $tmp."\n";
					}
					$status = 1;
					# print "debug0-1:0->$status:$wd:$#outstr\n" if ($debugprint == 1);
					@outstr = ();
					# @inwds = ();
					push @commentStr, $wd;
				}
				elsif ($wd =~ /($kws2)/){
					if ($#outstr > -1){
						$tmp = join('', @outstr);
						# $tmp =~ s/;/;\n/go;
						$tmp =~ s/\n+/\n/go;
						print ofp $tmp."\n";
					}
					$status = 2;
					@outstr = ();
					# @inwds = ();
					push @commentStr, $wd;
					# print "debug0-1:0->$status:$wd:$#outstr:$#commentStr\n" if ($debugprint == 1);
				}
				elsif ($wd =~ /($kwq)/){
					push @outstr, $wd;
					$status = 3;
				}
				elsif ($wd =~ /($kwdq)/){
					push @outstr, $wd;
					$status = 4;
				}
				else{
					push @outstr, $wd;
					# @commentStr = ();
				}
			}
			elsif ($status == 1){
				if ($wd =~ /($kwe)/){
					push @commentStr, $wd;
					$tmp = join('', @commentStr);
					# $tmp =~ s/^\s+//;
					$tmp =~ s/\n+/\n/go;
					print ofp2 $tmp."\n";
					@commentStr = ();
					# @outstr = ();
					$status = 0;
					# print "debug0-1:1->$status:$wd:$#outstr\n" if ($debugprint == 1);
				}
				else{
					# print "debug0-1:1->$status:$wd:$#outstr\n" if ($debugprint == 1);
					push @commentStr, $wd;
				}
			}
			elsif ($status == 2){
				# print "debug0-1:$status:$wd:$#outstr:$#commentStr\n" if ($debugprint == 1);
				push @commentStr, $wd;
				if ($wd =~ /\n/){
					$status = 0;
				}
			}
			elsif ($status == 3){
				# print "debug0-1:$status:$wd:$#outstr:$#commentStr\n" if ($debugprint == 1);
				push @outstr, $wd;
				if ($wd =~ /($kwq)/){
					$status = 0;
				}
			}
			elsif ($status == 4){
				# print "debug0-1:$status:$wd:$#outstr:$#commentStr\n" if ($debugprint == 1);
				push @outstr, $wd;
				if ($wd =~ /($kwdq)/){
					$status = 0;
				}
			}
			# if ($status == 2){
			# 	$status = 0;
			# }
		}
		@inwds = nextToken(fp, $de);
	}
	if ($#outstr > -1){
		$tmp = join('', @outstr);
		# $tmp =~ s/;/;\n/go;
		$tmp =~ s/\n+/\n/go;
		print ofp $tmp."\n";
		@outstr = ();
		# @inwds = ();
	}
	if ($#commentStr > -1){
		$tmp = join('', @commentStr);
		# $tmp =~ s/^\s+//;
		$tmp =~ s/\n+/\n/go;
		print ofp2 $tmp."\n";
		@commentStr = ();
	}
	close(ofp);
	close(ofp2);
	close(fp);
}

sub nextToken {
	my $fp = shift;
	my $de = shift;
	my @stack2;
	my $str = '';
	# print "\nnextToken\n";
	while (read($fp, $ch, 1)) {
		# print "$ch";
		if ($ch =~ /($de)/){
			if ($str ne ''){
				push @stack2, $str;
			}
			push @stack2, $ch;
			# $str .= $ch;
			$str = '';
			last;
		}
		else{
			$str .= $ch;
			if ($str =~ /(.+?)($de)/){
				push @stack2, $1;
				push @stack2, $2;
				$str = '';
				last;
			}
		}
	}
	# $str =~ s/\s+//go;
	return @stack2;
}

sub lexer {
	my $inline = shift;
	my $de = shift;
	my @stack2;
	my $str = '';
	foreach my $ch (split(//, $inline)) {
		if ($ch =~ /($de)/){
			if ($str ne ''){
				push @stack2, $str;
			}
			push @stack2, $ch;
			# if ($ch !~ /^\s+$/){
			# 	push @stack2, $ch;
			# }
			$str = '';
		}
		else{
			$str .= $ch;
			if ($str =~ /(.+?)($de)/){
				push @stack2, $1;
				push @stack2, $2;
				$str = '';
			}
		}
	}
	if ($str ne ''){
		push @stack2, $str;
	}
	# print "debug:lexer:".join('|', @stack2)."\n";
	return @stack2;
}

sub handler {  # 1st argument is a signal name
	my ($sig) = @_;
	if (defined($sig)){
		print "Caught a SIG$sig--shutting down\n";
		close(LOG);
	}
	close(fp);
	close(ofp);
	close(ofp2);
	exit;
}
