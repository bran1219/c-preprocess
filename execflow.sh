#! /bin/sh
#   -D_MSC_VER -D__GNUC__ -D__x86_64__ -DHAVE_SSE4 -DUSI -DDFPN -DDFPN_DBG -DTLP -D__ICC -DINANIWA_SHIFT -DDFPN_CLIENT -DCSASHOGI \
#   -UNDEBUG -UMINIMUM -UBK_ULTRA_NARROW -UBK_SMALL -UBK_TINY -UNO_LOGGING -UNO_STDOUT -UNO_LOGGING -UDBG_EASY \
#   --cpp='C:/mingw/bin/cpp.exe' $*  > tmp.txt

cflow --format=posix --omit-arguments \
   --level-indent='0=\t' --level-indent='1=\t' \
   --level-indent=start='\t' -b \
   $*  > tmp.txt 2> tmpError.txt
#cflow2dot < tmp.txt > tmpdot.txt
perl myCflow2Dot.pl tmp.txt > tmpmydot.txt
perl countLeafs2.pl tmpmydot.txt 0 > tmpmydotcount.txt
cat structs/*.[ch] > structs.txt
perl mystructs2dot.pl structs.txt > structsmydot.txt
perl countLeafs2.pl structsmydot.txt 0 > structsmydotcount.txt

exedot.sh structsmydot.txt
exedot.sh tmpmydot.txt

