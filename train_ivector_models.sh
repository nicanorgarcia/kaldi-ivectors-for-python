#!/bin/bash
# Copyright 2016  Nicanor garcia
# Apache 2.0.
#

delta_order=0

M=$1
ivector_dim=$2
featFile=$3
modelDir=$4

g="_gi"

. path.sh

#Compute feats
echo $featFile
if [ ! -f ${featFile} ]; then echo "There are no characteristics to process"; exit 1; fi

# Generate the UBMs
k=$( echo "l($M)/l(2)" | bc -l )
k=${k%.*}
num_gselect=$((k+1))


mDir=$modelDir/M${M}
if [ ! -d $mDir ]; then	mkdir -p $mDir; fi

train_diagUBM.sh --num-gselect $num_gselect --delta_order $delta_order $featFile $M $mDir || exit 1;
train_fullUBM.sh --num-gselect $num_gselect $featFile $mDir $mDir/ubm${g} || exit 1;
train_ivector_extractor.sh --ivector-dim $ivector_dim --num-gselect $num_gselect $mDir/ubm${g}/final.ubm $featFile $mDir/extractor${g} || exit 1;
