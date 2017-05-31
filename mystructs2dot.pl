use Cwd;

if ($#ARGV<0){
	# printf "usage: perl mystructs2dot.pl <file>\n";
	exit(0);
}

my $file = $ARGV[0];
#print "$pat $the_glob\n";
my $dir = Cwd::getcwd();
chdir($dir);

my %nodesDic = ();
my $tline = '';
my $linenum = 0;
my @stack = ();
my @outstr = ();
my $status = 1;
my $preStatus = 0;
my $tline = '';
my @inwds = ();
my $de = '\s|{|=|}|;|,';
my $tmpID = 0;
# my $currentNodeId = 0;
my $within = 0;

print "digraph mygraph {\n";
print "node [shape=plaintext];edge [color=black style=dashed];\n";

open(fp, "<$file") or die "can not open $file.";
while(<fp>){
	$linenum++;
	if ($_ =~ /^\s*#/ || $_ =~ /^\s*$/){
		next;
	}
	$tline = $_;
	$tline =~ s/\n/ /go;
	# typedef struct union enum
	my $oldtypename = '';
	my $newtypename = '';
	# print "debug5-0:$status:$within:$tline\n";
	@inwds = lexer($tline);
	foreach my $wd (@inwds){
		# print "debug5-1:$status:$within:$wd\n";
		if ($status == 1){
			if ($wd eq 'typedef'){
				$status = 2;
				@outstr = ();
			}
			elsif ($wd eq 'struct' || $wd eq 'union'){
				$status = 3;
				@outstr = ();
			}
			elsif ($wd eq ';'){
				$status = 1;
				@outstr = ();
				$within = 0;
				$oldtypename = '';
				$newtypename = '';
			}
		}
		elsif ($status == 2){
			# typedef
			$oldtypename = $wd;
			if ($wd eq 'struct' || $wd eq 'union'){
				$preStatus = 2;
				$status = 3;
			}
			elsif ($wd eq ';'){
				$status = 1;
				$within = 0;
				$oldtypename = '';
				$newtypename = '';
			}
			elsif ($wd eq '='){
			}
			else{
				push @outstr, $wd; #$newtypename
			}
		}
		elsif ($status == 3){
			# stuct
			if ($wd eq ';'){
				$status = 1;
				# print "debug5-2:$status:$within:$wd\n";
				if ($within == 1){
					# $newtypename = pop @outstr;
					if ($#outstr > -1){
						$tmpID++;
						for (my $i=0; $i<=$#outstr; $i++){
							if (!exists($nodesDic{$outstr[$i]})){
								$nodesDic{$outstr[$i]} = $tmpID;
								print "node_".$tmpID.' [ label="'.join('\n', @outstr).'" ]'."\n";
							}
						}
						# $currentNodeId = $tmpID;
						@outstr = ();
					}
				}
				else{
					if ($#outstr > -1){
						$tmpID++;
						# $newtypename = pop @outstr;
						# $nodesDic{$newtypename} = $tmpID;
						# $oldtypename = pop @outstr;
						# $nodesDic{$oldtypename} = $tmpID;
						if (!exists($nodesDic{$outstr[$#outstr]})){
							print "node_".$tmpID.' [ label="'.join('\n', @outstr).'" ]'."\n";
						}
						@outstr = ();
					}
				}
				$within = 0;
				$oldtypename = '';
				$newtypename = '';
			}
			elsif ($wd eq '{'){
				$status = 4;
				$within = 1;
				push @stack, $linenum;
			}
			elsif ($wd eq '='){
				$status = 1;
			}
			elsif ($wd eq ','){
			}
			else{
				if ($within == 0){
					push @outstr, $wd; #$oldtypename
				}
				elsif ($within == 1){
					push @outstr, $wd; # $newtypename
				}
				# if ($within == 1){
				# 	push @outstr, $wd; #$newtypename
				# }
			}
		}
		elsif ($status == 4){
			if ($wd eq '{'){
				push @stack, $linenum;
				$within = 1;
			}
			elsif ($wd eq '}'){
				pop @stack;
				if ($#stack == -1){
					$preStatus = 4;
					$status = 3;
				}
			}
			elsif ($wd eq ';'){
			}
			elsif ($wd eq ','){
			}
			elsif ($wd eq 'struct' || $wd eq 'union'){
			}
			else{
				# if ($#outstr == -1){
				# 	push @outstr, $wd; #$oldtypename
				# }
			}
		}
		# print "debug5-3:$status:$within:$wd\n";
	}
}

close(fp);

# print "nodesDic...\n";
# foreach my $kw (keys %nodesDic){
# 	print "$kw => $nodesDic{$kw}\n";
# }


my %edgesDic = ();
open(fp, "<$file") or die "can not open $file.";
while(<fp>){
	$linenum++;
	if ($_ =~ /^\s*#/ || $_ =~ /^\s*$/){
		next;
	}
	$tline = $_;
	$tline =~ s/\n/ /go;
	# typedef struct union enum
	my $oldtypename = '';
	my $newtypename = '';
	# print "debug5-0:$status:$within:$tline\n";
	@inwds = lexer($tline);
	foreach my $wd (@inwds){
		# print "debug5-1:$status:$within:$wd\n";
		if ($status == 1){
			if ($wd eq 'typedef'){
				$status = 2;
				# @outstr = ();
				# push @outstr, $wd;
			}
			elsif ($wd eq 'struct' || $wd eq 'union'){
				$status = 3;
				# @outstr = ();
				# push @outstr, $wd;
			}
			elsif ($wd eq ';'){
				$status = 1;
				# push @outstr, $wd;
				# if ($within == 1){
				# 	my $tmpstr = join(' ', @outstr);
				# 	if ($tmpstr =~ /(typedef|struct|union)/ && $tmpstr !~ /=/){
				# 		# print join(' ', @outstr)."\n";
				# 	}
				# }
				# @outstr = ();
				# @inwds = ();
				$within = 0;
				# $oldtypename = '';
				# $newtypename = '';
			}
		}
		elsif ($status == 2){
			# typedef
			# push @outstr, $wd;
			# $oldtypename = $wd;
			if ($wd eq 'struct' || $wd eq 'union'){
				$preStatus = 2;
				$status = 3;
			}
			elsif ($wd eq ';'){
				$status = 1;
				# push @outstr, $wd;
				# if ($within == 1){
				# 	my $tmpstr = join(' ', @outstr);
				# 	if ($tmpstr =~ /(typedef|struct|union)/ && $tmpstr !~ /=/){
				# 		# print join(' ', @outstr)."\n";
				# 	}
				# }
				@outstr = ();
				# @inwds = ();
				$within = 0;
				# $oldtypename = '';
				# $newtypename = '';
			}
			elsif ($wd eq '='){
			}
			else{
				# if ($oldtypename eq ''){
				# 	$oldtypename = $wd;
				# }
				# else{
				# 	$tmpID++;
				# 	$newtypename = $wd;
				# 	$nodesDic{$newtypename} = $oldtypename;
				# 	print "node_".$tmpID.' [ label="'.$newtypename.'" ]'."\n";
				# }
			}
		}
		elsif ($status == 3){
			# stuct
			# push @outstr, $wd;
			if ($wd eq ';'){
				$status = 1;
				# print "debug5--2.1:$status:$within:$wd\n";
				# if ($within == 1){
					# my $tmpstr = join(' ', @outstr);
					# if ($tmpstr =~ /(typedef|struct|union)/ && $tmpstr !~ /=/){
					# 	# print join(' ', @outstr)."\n";
					# }
					# if (exists($nodesDic{$newtypename})){
						# printf("\tnode_".($currentNodeId+1)." -> node_".$nodesDic{$newtypename}." ;\n");
					# }
					# else{
					# 	$tmpID++;
					# 	# $newtypename = $wd;
					# 	$nodesDic{$newtypename} = $tmpID; #$oldtypename;
					# 	print "node_".$tmpID.' [ label="'.$newtypename.'" ]'."\n";
					# 	$currentNodeId = $tmpID;
					# }
				# }
				# else{
					# my $tmpstr = join(' ', @outstr);
					# if ($tmpstr =~ /(typedef|struct|union)/ && $tmpstr !~ /=/){
					# 	# print join(' ', @outstr)."\n";
					# }
				# }
				@outstr = ();
				# @inwds = ();
				$within = 0;
				# $oldtypename = '';
				# $newtypename = '';
			}
			elsif ($wd eq '{'){
				$status = 4;
				$within = 1;
				# push @outstr, "\n";
				push @stack, $linenum;
			}
			elsif ($wd eq '='){
				$status = 1;
			}
			else{
				if ($within == 1){
					$newtypename = $wd;
					if (exists($nodesDic{$newtypename})){
						for (my $nid = shift @outstr; $nid ne ''; $nid = shift @outstr){
							if (!exists($edgesDic{$nodesDic{$newtypename}.$nid})){
								printf("\tnode_".$nodesDic{$newtypename}." -> node_".$nid." ;\n");
								$edgesDic{$nodesDic{$newtypename}.$nid} = 1;
							}
						}
					}
				}
			}
		}
		elsif ($status == 4){
			# push @outstr, $wd;
			if ($wd eq '{'){
				push @stack, $linenum;
				$within = 1;
			}
			elsif ($wd eq '}'){
				pop @stack;
				if ($#stack == -1){
					$preStatus = 4;
					$status = 3;
				}
			}
			elsif ($wd eq ';'){
				# push @outstr, "\n";
			}
			elsif ($wd eq 'struct' || $wd eq 'union'){
			}
			else{
				if (exists($nodesDic{$wd})){
					push @outstr, $nodesDic{$wd};
					# printf("push $nodesDic{$wd}\n");
				}
			}
		}
		# print "debug5-3:$status:$within:$wd\n";
	}
}

close(fp);

print "}\n";



sub lexer{
	$inline = shift;
	my @stack2;
	my $str = '';
	foreach my $ch (split(//, $inline)) {
		if ($ch =~ /($de)/){
			if ($str ne ''){
				push @stack2, $str;
			}
			if ($ch !~ /\s+/){
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
	return @stack2;
}
