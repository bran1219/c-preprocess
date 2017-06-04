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
my $debugprint = 0;
my @file_list;
my @tmpAry = split('/', $the_glob);
if ($#tmpAry>-1){
	$dir .= '/'.join('/', @tmpAry[0..$#tmpAry-1]);
}
my @file_list = glob($the_glob);
# print "debug1:$dir\n";
foreach my $file (@file_list){
	@tmpAry = split('/', $file);
	my $file2 = $tmpAry[-1];
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
sub extractFunction{

}

# todo
sub extractStruct{
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
	# $de = '\s|{|}|;';
	# 
	while(<fp>){
		my @lines = ();
		my $status_10 = 0;
		$linenum++;
		if ($_ =~ /^\s*#/ || $_ =~ /^\s*$/){
			next;
		}
		$tline .= $_;
		# print "\n";
		# print "debug5-a:$status:$tline\n";
		# if (($tline !~ /;/ || $tline !~ /}/) && !eof){
		# 	next;
		# }
		# 1.0 以上になる
		$tline =~ s/\n/ /go;
		# print "debug5--0:$status:$tline\n";
		if ($status == 0){
			$status_10 = 1;
			if ($tline =~ /\)\s*{/){
				$status = -1;
				my $count = (() = $tline =~ /{/g);
				for (my $i=0; $i<$count; $i++){
					push @stack, $linenum;
				}
				$count = (() = $tline =~ /}/g);
				for (my $i=0; $i<$count; $i++){
					pop @stack;
				}
				if ($#stack == -1){
					$status = 0;
				}
				# print "debug5-b:$status:$count:$#stack:$tline\n";
				$tline = '';
				next;
			}
		}
		elsif ($status == -1){
			$status_10 = 1;
			my $count = (() = $tline =~ /{/g);
			for (my $i=0; $i<$count; $i++){
				push @stack, $linenum;
			}
			$count = (() = $tline =~ /}/g);
			for (my $i=0; $i<$count; $i++){
				pop @stack;
			}
			if ($#stack == -1){
				$status = 0;
			}
			# print "debug5-c:$status:$count:$#stack:$tline\n";
			$tline = '';
			next;
		}

		if ($status_10 == 1 && $tline =~ /;/){
			$status = 1;
		}
		if (eof){
			$lines[0] = $tline;
			$lines[1] = '';
		}
		else{
			# 途中分を次回の処理に繰延べる
			@lines = split(';', $tline);
			$tline = $lines[$#lines];
		}
		for (my $i=0; $i<$#lines; $i++){
			# typedef struct union enum
			my $line = $lines[$i].';';
			my $oldtypename = '';
			my $newtypename = '';
			# print "debug5-d:$i:$status:$line\n";
			# push @inwds, lexer($line);
			@inwds = lexer($line, '\s|{|}|;');
			foreach my $wd (@inwds){
				# print "debug5-e:$status:$within:$wd\n";
				if ($status == 0){
					# add words after ';'
					# die "error status 0";
				}
				elsif ($status == 1){
					if ($wd eq 'typedef'){
						$status = 2;
						@outstr = ();
						push @outstr, $wd;
					}
					elsif ($wd eq 'struct' || $wd eq 'union'){
						$status = 3;
						@outstr = ();
						push @outstr, $wd;
					}
					elsif ($wd eq ';'){
						$status = 0;
						push @outstr, $wd;
						if ($within == 1){
							my $tmpstr = join(' ', @outstr);
							if ($tmpstr =~ /(typedef|{|})/ && $tmpstr !~ /=/){
								print ofp $tmpstr."\n";
							}
						}
						@outstr = ();
						@inwds = ();
						$within = 0;
					}
				}
				elsif ($status == 2){
					# typedef
					push @outstr, $wd;
					$oldtypename = $wd;
					if ($wd eq 'struct' || $wd eq 'union'){
						$preStatus = 2;
						$status = 3;
					}
					elsif ($wd eq ';'){
						$status = 0;
						push @outstr, $wd;
						if ($within == 1){
							my $tmpstr = join(' ', @outstr);
							if ($tmpstr =~ /(typedef|{|})/ && $tmpstr !~ /=/){
								print ofp $tmpstr."\n";
							}
						}
						@outstr = ();
						@inwds = ();
						$within = 0;
					}
				}
				elsif ($status == 3){
					# stuct
					push @outstr, $wd;
					if ($wd eq ';'){
						$status = 0;
						# print "debug5-2.1:$status:$within:$#outstr:$wd\n";
						if ($within == 1){
							my $tmpstr = join(' ', @outstr);
							if ($tmpstr =~ /(typedef|{|})/ && $tmpstr !~ /=/){
								print ofp $tmpstr."\n";
								# print "debug5-2.2:$status:$within:$#outstr:$tmpstr\n";
							}
						}
						else{
							my $tmpstr = join(' ', @outstr);
							if ($tmpstr =~ /(typedef|{|})/ && $tmpstr !~ /=/){
								print ofp $tmpstr."\n";
								# print "debug5-2.3:$status:$within:$#outstr:$tmpstr\n";
							}
						}
						@outstr = ();
						@inwds = ();
						$within = 0;
					}
					elsif ($wd eq '{'){
						$status = 4;
						$within = 1;
						push @outstr, "\n";
						push @stack, $linenum;
					}
					else{
						if ($preStatus == 2){
							$oldtypename .= ' '.$wd;
						}
						elsif ($preStatus == 4){
							$newtypename = $wd;
						}
					}
				}
				elsif ($status == 4){
					push @outstr, $wd;
					if ($wd eq '{'){
						push @stack, $linenum;
					}
					elsif ($wd eq '}'){
						pop @stack;
						if ($#stack == -1){
							$preStatus = 4;
							$status = 3;
						}
					}
					elsif ($wd eq ';'){
						push @outstr, "\n";
					}
					elsif ($wd eq 'struct' || $wd eq 'union'){
					}
				}
				# print "debug5-f:$status:$within:$wd\n";
			}
		}
	}
	# if ($tline ne ''){
	# 	print ofp $tline;
	# }
	close(ofp);
	close(fp);
}

sub reversePolishNotation{
	my $conditions = shift;
	my @result = ();
	my @rpnstack = ();
	# $de = '!|\s|\(|\)|>|<|=';
	# print "debug4-1:$conditions\n";
	$conditions =~ s/defined\((.+?)\)/defined$1/go;
	# $conditions =~ s/!\s*/!/go;
	# print "debug4-2:$conditions\n";
	my @inwds = lexer($conditions, '!|\s|\(|\)|>|<|=');
	for (my $i=0; $i<=$#inwds; $i++){
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
			elsif ($inwds[$i] =~ /defined(.+)/){
				my $tmp = $1;
				# print "debug4-5:$tmp => $mydefs->{$tmp}\n";
				if (defined($mydefs->{$tmp})){
					$digit = 1;
				}
				else{
					$digit = 0;
				}
			}
			elsif (defined($mydefs->{$inwds[$i]})){
				$digit = $mydefs->{$inwds[$i]};
			}
			else{
				$digit = 0;
			}
			# if ($inwds[$i] =~ /^!/){
			# 	$digit = ($digit == 0) ? 1 : 0;
			# }
			push @result, \$digit;
			if ($$rpnstack[$#rpnstack] eq '!') {
				my $op = pop @rpnstack;
				push @result, $op;
			}
		}
	}
	while ($#rpnstack > -1) {
		my $op = pop @rpnstack;
		push @result, $op;
	}
	return @result;
}

sub parsecondition{
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
	return $$val;
}

sub procifdef{
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
	my $kw1 = '#\s*if';
	my $kw2 = '#\s*else';
	my $kw3 = '#\s*endif';
	my $kw4 = '#\s*define';
	my $kw5 = '#\s*elif';
	# $de = '\s';
	# binmode fp, ':encoding(utf8)';
	# binmode fp;
	while(<fp>){
		$linenum++;
		#if ($_ =~ //){
		#	if ($debugprint == 0){
		#		# print "debug start---------\n";
		#		# $debugprint = 1;
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
		# print "debug2-1 all:$status:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$tline\n" if ($debugprint == 1);
		if ($tline =~ /($kw1|$kw2|$kw3|$kw5)/){
			$wd = $tline;
			# print "debug2-2start:$status:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$wd\n" if ($debugprint == 1);
			if ($status == 0){
				if ($wd =~ /^($kw1)\s+(.+)$/){
					$status = 1;
					push @conditions, $curcond;
					push @condstrs, $curcondstr;
					$curcondstr = $2;
					$curcond = parsecondition($curcondstr);
				}
				else{
					push @outstr, $wd;
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
					$status = 2;
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
					$curcond = 1 - $curcond;
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
					if ($curcond == 1){
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
			# print "debug2-5a:$status:$curcond:$curcondstr:$#conditions:".join(' ', @conditions).":$tline\n" if ($debugprint == 1);
			if ($curcond == 1){
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

sub decomment{
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
	my @outstr = ();
	my @commentStr = ();
	my $status = 0;
	my $linenum = 0;
	my @inwds = ();
	# $de = '\s';
	while(<fp>){
		my $tline = $_;
		$linenum++;
		# print "debug1-1:$tline";
		while ($tline =~ /($kws)(.*?)($kwe)/){
			my $comment = $2;
			# print "$linenum:$comment\n"; 
			$tline =~ s/($kws)(.*?)($kwe)//;
			if ($comment !~ /^\s*$/){
				push @commentStr, $comment;
			}
		}
		# $tline =~ s/$kws(.*)$kwe//go;
		$tline =~ s/^\s+//;
		$tline =~ s/\s+$//;
		if ($tline =~ /^$/){
			next;
		}
		# print "debug1-2:$tline\n";
		if ($#commentStr > -1){
			print ofp2 join(' ', @commentStr)."\n";
			@commentStr = ();
		}
		# $debugprint = 0;
		# if ($tline =~ /Result/){
			$debugprint = 1;
		# }
		# push @inwds, lexer($tline);
		@inwds = lexer($tline, '\s|$kws2');
		# print "line : ".join(' ', @inwds)."\n";
		foreach my $wd (@inwds){
			# print "debug0-2start:$status:$wd:$#outstr:$#commentStr\n" if ($debugprint == 1);
			$wd =~ s/\s+//go;
			if ($status == 0){
				if ($wd =~ /($kws)/){
					if ($#outstr > -1){
						print ofp join(' ', @outstr)."\n";
					}
					$status = 1;
					# print "debug0-1:0->$status:$wd:$#outstr\n" if ($debugprint == 1);
					@outstr = ();
					# @inwds = ();
					push @commentStr, $wd;
				}
				elsif ($wd =~ /($kws2)/){
					if ($wd =~ /"/){
						push @outstr, $wd;
					}
					else{
						if ($#outstr > -1){
							print ofp join(' ', @outstr)."\n";
						}
						$status = 2;
						@outstr = ();
						# @inwds = ();
						push @commentStr, $wd;
						# print "debug0-1:0->$status:$wd:$#outstr:$#commentStr\n" if ($debugprint == 1);
					}
				}
				else{
					push @outstr, $wd;
					# @commentStr = ();
				}
			}
			elsif ($status == 1){
				if ($wd =~ /($kwe)/){
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
			}
			# print "debug0-2  end:$status:$wd:$#outstr:$tline\n" if ($debugprint == 1);
		}
		if ($status == 2){
			$status = 0;
		}
		if ($#outstr > -1){
			print ofp join(' ', @outstr)."\n";
			@outstr = ();
			# @inwds = ();
		}
		if ($#commentStr > -1){
			print ofp2 join(' ', @commentStr)."\n";
			@commentStr = ();
		}
	}
	close(ofp);
	close(ofp2);
	close(fp);
}

sub lexer{
	my $inline = shift;
	my $de = shift;
	my @stack2;
	my $str = '';
	foreach my $ch (split(//, $inline)) {
		if ($ch =~ /($de)/){
			if ($str ne ''){
				push @stack2, $str;
			}
			if ($ch !~ /^\s+$/){
				push @stack2, $ch;
			}
			$str = '';
		}
		else{
			$str .= $ch;
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
