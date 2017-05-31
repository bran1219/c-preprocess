

if ($#ARGV<0){
	printf("usage:myCflow2Dot.pl <cflowfilename>\n");
	exit(0);
}

my $file = ($ARGV[0]);

%nodesDic = ();
my @tmpAry = ();
my $tmpHash = ();
my $tmpID = "";
my @pstack = ();
open(fp, "<$file") or die "can not open $file.";
# printf("$file Aa");
printf("digraph mygraph {\n");
printf("node [shape=plaintext];edge [color=black style=dashed];\n");
while(<fp>){
	my $tline = $_;

	# printf($_);
	if ($tline =~ /^\s*(\d+)(\s+)(.+?): (.+?), <(.+)>/){
		# 1 	hip_read_command: void (), <hip_hip.c 3342>
		#$1行番号 $2level $3関数名 $4戻り値 $5ファイル
		$tmpID = $1;
		# @tmpAry = split(/\s/, $2);
		$level = length($2);
		# $level = scalar(@tmpAry);
		$tmpHash = {type=>1, level=>$level, func=>$3, retval=>" $4", filename=>$5};
	}
	elsif ($tline =~ /^\s*(\d+)(\s+)(.+?): <>/){
		# 2 		uint8: <>
		$tmpID = $1;
		# @tmpAry = split(/\s/, $2);
		$level = length($2);
		# $level = scalar(@tmpAry);
		$tmpHash = {type=>2, level=>$level, func=>$3, retval=>$4, filename=>" 0"};
	}
	elsif ($tline =~ /^\s*(\d+)(\s+)(.+?): (\d+)/){
		# 過去に登録したノードを参照する
		# 22 			CSL_MakeSense: 8
		$tmpID = $4;
		# @tmpAry = split(/\s/, $2);
		$level = length($2);
		# $level = scalar(@tmpAry);
		$tmpHash = {type=>3, level=>$level, func=>$3, retval=>$4, filename=>" 0"};
	}

	if (!exists($nodesDic{$tmpID})){
		$nodesDic{$tmpID} = $tmpHash;
		$tmpHash->{filename} =~ s/ /:/;
		printf("node_".$tmpID.' [ label="'.$tmpHash->{func}.'\n'.$tmpHash->{retval}.'\n'.$tmpHash->{filename}.'" ]'."\n");
	}

	if ($#pstack<0){
# printf("0:$level : $nodesDic{$pstack[$#pstack]}->{level}\n");
		push(@pstack, $tmpID);
	}
	elsif ($level > $nodesDic{$pstack[$#pstack]}->{level}){
# printf("A:$level : $nodesDic{$pstack[$#pstack]}->{level}\n");
		if ($tmpHash->{type} == 3){
			if ($#pstack>=0){
				printf("\tnode_".$pstack[$#pstack]." -> node_".$tmpID." ;\n");
			}
		}
		else{
			if ($#pstack>=0){
				printf("\tnode_".$pstack[$#pstack]." -> node_".$tmpID." ;\n");
			}
			push(@pstack, $tmpID);
		}
	}
	elsif ($level == $nodesDic{$pstack[$#pstack]}->{level}){
# printf("B:$level : $nodesDic{$pstack[$#pstack]}->{level}\n");
		pop(@pstack);
		if ($tmpHash->{type} == 3){
			if ($#pstack>=0){
				printf("\tnode_".$pstack[$#pstack]." -> node_".$tmpID." ;\n");
			}
		}
		else{
			if ($#pstack>=0){
				printf("\tnode_".$pstack[$#pstack]." -> node_".$tmpID." ;\n");
			}
			push(@pstack, $tmpID);
		}
	}
	elsif ($level < $nodesDic{$pstack[$#pstack]}->{level}){
		my $leveldiff = $nodesDic{$pstack[$#pstack]}->{level} - $level;
		for (my $i=0; $i<=$leveldiff; $i++){
			pop(@pstack);
		}
		if ($tmpHash->{type} == 3){
			if ($#pstack>=0){
				printf("\tnode_".$pstack[$#pstack]." -> node_".$tmpID." ;\n");
			}
		}
		else{
			if ($#pstack>=0){
				printf("\tnode_".$pstack[$#pstack]." -> node_".$tmpID." ;\n");
			}
			push(@pstack, $tmpID);
		}
	}
}
printf("}\n");
close(fp);
