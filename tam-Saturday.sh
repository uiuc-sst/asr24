#!/bin/bash

# # Only for campus cluster.
# module unload gcc/4.7.1 gcc/4.9.2
# module load python/2 # Also loads gcc/6.2.0, says module show python/2
# module unload gcc/6.2.0 # don't conflict with 7.2.0
# module load gcc/7.2.0 # for GLIBCXX_3.4.23

. cmd.sh
. path.sh

# This reads utt2spk and scp.wav, built by tam-Saturday-init.sh.
online2-wav-nnet3-latgen-faster \
--online=false \
--do-endpointing=false \
--frame-subsampling-factor=3 \
--config=exp/tdnn_7b_chain_online/conf/online.conf \
--max-active=7000 \
--beam=15.0 \
--lattice-beam=6.0 \
--acoustic-scale=1.0 \
--word-symbol-table=exp/tdnn_7b_chain_online/graph_pp/words.txt \
exp/tdnn_7b_chain_online/final.mdl \
exp/tdnn_7b_chain_online/graph_pp/HCLG.fst \
'ark:utt2spk' \
'scp:wav'.scp \
'ark:/dev/null'
