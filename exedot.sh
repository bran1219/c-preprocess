#! /bin/sh

dot -Gshape=10 -Gfontsize=10 -Garrowsize=0.2 -Gnormarize=true -Goverlap=false \
	-Grankdir=LR \
	-Earrowhead=halfopen \
	-Nfontsize=10 \
	-Tsvg -Kdot -O -y -x -Lg $*

# dot -Kneato -x -Gconcentrate=true
#	-EheadURL=#\\T -EtailURL=#\\H -Earrowhead=halfopen \
#	-Efontsize=8 -Efontcolor=blue -Eheadlabel=\\T -Etaillabel=\\H \
