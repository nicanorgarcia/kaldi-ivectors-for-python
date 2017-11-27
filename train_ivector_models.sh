#!/bin/bash
# Copyright 2016  Nicanor garcia
# Apache 2.0.
#

M=$1
ivector_dim=$2
num_gselect=$3
featFile=$4
mDir=$5

. path.sh

#Compute feats
echo $featFile
if [ ! -f ${featFile} ]; then echo "There are no characteristics to process"; exit 1; fi

# Generate the UBMs
# k=$( echo "l($M)/l(2)" | bc -l )
# k=${k%.*}
# num_gselect=$((k+1))


if [ ! -d $mDir ]; then	mkdir -p $mDir; fi
kaldi_ivector/train_diagUBM.sh --num-gselect $num_gselect $featFile $M $mDir || exit 1;
kaldi_ivector/train_fullUBM.sh --num-gselect $num_gselect $featFile $mDir $mDir/ubm || exit 1;
kaldi_ivector/train_ivector_extractor.sh --ivector-dim $ivector_dim --num-gselect $num_gselect $mDir/ubm/final.ubm $featFile $mDir/extractor || exit 1;
