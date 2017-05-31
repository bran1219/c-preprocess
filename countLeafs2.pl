

if ($#ARGV<1){
	printf("usage:countLeafs2.pl <filename> <th>\n");
	exit(0);
}

my $file = $ARGV[0];
my $cth = $ARGV[1];

%nodesDic = ();
# %nodesDic2 = ();
%nodesCallerDic = ();
%nodesCalleeDic = ();

open(fp, "<$file") or die "can not open $file.";
# printf("$file Aa");
while(<fp>){
    my $tline = $_;
    # printf($_);
    if ($tline =~ /^(node_\d+) \[ label="(.+?)(\\n.+)?" \]/){
        $nodesDic{$1} = [$tline, $2];
        # if ($tline =~ /^(node_\d+) \[ label="(.+?)\\n.+" \]/){
        #     # node_2 [ label="strcmp\n\n:0" ]
        #     if (!exists($nodesDic2{$2})){
        #         $nodesDic2{$2} = ();
        #     }
        #     push $nodesDic2{$2}, $1;
        # }
    }
    elsif ($tline =~ /^\s+(node_\d+) -> (node_\d+) ;/){
        if (!exists($nodesCallerDic{$1})){
            $nodesCallerDic{$1} = "";
        }
        if (!exists($nodesCalleeDic{$2})){
            $nodesCalleeDic{$2} = "";
        }
        $nodesCallerDic{$1} .= "|$2";
        $nodesCalleeDic{$2} .= "|$1";
    }
}
close(fp);

for my $ks (keys %nodesDic){
    my $tmpAry1 = scalar(split("\\|", $nodesCallerDic{$ks})) - 1;
    my $tmpAry2 = scalar(split("\\|", $nodesCalleeDic{$ks})) - 1;
    $tmpAry1 = ($tmpAry1<0) ? 0 : $tmpAry1;
    $tmpAry2 = ($tmpAry2<0) ? 0 : $tmpAry2;
    my $tmp1 = $nodesDic{$ks}[0];
    my $tmp2 = $nodesDic{$ks}[1];
    $tmp1 =~ s/\n//;
    printf("$ks\t$tmp2\t$tmpAry1\t$tmpAry2\t$tmp1\n");
}

exit;

printf("digraph graph {\n");
printf("node [shape=plaintext];edge [color=black style=dashed];\n");
for my $ks (keys %nodesDic){
    my @tmpAry = split("\\|", $nodesCallerDic{$ks});
    # printf("$ks\t$#tmpAry\n");
    if ($#tmpAry > $cth) {
        if (exists($nodesDic{$ks})){
            printf($nodesDic{$ks});
            delete($nodesDic{$ks});
        }
        for (my $i=1; $i<=$#tmpAry; $i++){
            if (exists($nodesDic{$tmpAry[$i]})){
                printf($nodesDic{$tmpAry[$i]});
                delete($nodesDic{$tmpAry[$i]});
            }
            printf("\t$ks -> $tmpAry[$i];\n");
        }
    }
}
printf("}\n");


