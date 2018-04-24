#!/usr/bin/env bash

# Put a decoding configuration in $newlangdir/conf/*.conf.

if [ $# != 1 ]; then
  echo "Usage: $0 <newlangdir>"
  exit 1
fi
[ ! -d $1 ] && echo "$0: missing directory $1. Aborting." && exit 1
newlangdir=$1

# Set up environment variables.
. cmd.sh || exit 1
. path.sh || exit 1

# Input and output dir.
lang=$newlangdir/lang

# The script prepare_online_decoding.sh needs these inputs:
#   $lang/phones.txt
#   $lang/phones/silence.csl
#   exp/chain/tdnn_7b/*.*
#   exp/nnet3/extractor/*.*
 
steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf $lang exp/nnet3/extractor exp/chain/tdnn_7b $newlangdir || exit 1
chmod a-x+r $newlangdir/conf/*.conf
