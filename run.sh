#!/usr/bin/env bash

# Run each stage.

if [ $# != 1 ]; then
  echo "Usage: $0 <newlangdir>" # e.g., $0 tamil, or $0 russian.
  exit 1
fi
[ ! -d $1 ] && echo "$0: missing directory $1. Aborting." && exit 1

./mkprondict.py             $1 || exit 1
./newlangdir_train_lms.sh   $1 || exit 1
./newlangdir_make_graphs.sh $1 || exit 1
./newlangdir_make_confs.sh  $1 || exit 1

if false; then
  # todo: do this in a copy of $1, to not overwrite the Aspire-model HCLG.fst.
  ./newlangdir_make_graphs-cvteMandarin.sh $1 || exit 1
  # Verify that the CVTE ASR can transcribe, like ASpIRE.
  . cmd.sh && . path.sh
  echo "--mfcc-config=cvte/s5/exp/chain/tdnn/conf/mfcc.conf" > /tmp/conf
  echo "--ivector-extraction-config=cvte/s5/exp/chain/tdnn/conf/ivector_extractor.conf" >> /tmp/conf
  online2-wav-nnet3-latgen-faster \
    --online=false  --do-endpointing=false \
    --frame-subsampling-factor=3 \
    --config=/tmp/conf \
    --max-active=7000 \
    --beam=15.0  --lattice-beam=6.0  --acoustic-scale=1.0 \
    --word-symbol-table=$L/graph/words.txt \
    $L/final.mdl \
    $L/graph/HCLG.fst \
    'ark:echo utterance-id1 utterance-id1|' \
    'scp:echo utterance-id1 $L-8khz/FILENAME.wav|' \
    'ark:/dev/null'
fi
