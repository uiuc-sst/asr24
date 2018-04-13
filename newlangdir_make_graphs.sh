#!/usr/bin/env bash

# Try this on ifp-53, because campus cluster lacks a UTF-8-compatible perl needed by utils/validate_dict_dir.pl, called by utils/prepare_lang.sh.
# (Runs on a Mac in a few hours.  Much faster than Sequitur, a full weekend.)
# Example inputs and outputs are /scratch/users/jhasegaw/kaldi/egs/aspire/s5/{russian,tamil} (5 GB and 1 GB).

if [ $# != 1 ]; then
  echo "Usage: $0 <newlangdir>" # e.g., $0 tamil, or $0 russian.
  echo "Inputs and outputs are all in <newlangdir>."
  echo "Inputs: lang/clean.txt,"
  echo "        local/dict/{lexicon.txt, extra_questions.txt, nonsilence_phones.txt, optional_silence.txt, silence_phones.txt, topo, words.txt}."
  echo "Intermediate outputs: local/dict/lexiconp.txt, dict/L.fst, lang/L.fst"
  echo "Output: graph/HCLG.fst."
  echo "SRILM must be in your path."
  exit 1
fi
[ ! -d $1 ] && echo "$0: missing directory $1. Aborting." && exit 1
newlangdir=$1

# Set up environment variables.
. cmd.sh
. path.sh

command -v ngram-count 1>/dev/null 2>&1 || { echo "$0: failed to find SRILM tools. Install SRILM and update path.sh."; exit 1; }

# Get the paths of our input files.
model=exp/tdnn_7b_chain_online
phones_src=exp/tdnn_7b_chain_online/phones.txt
dict_src=${newlangdir}/local/dict
lm_src=${newlangdir}/lang/lm.arpa
 
lang=${newlangdir}/lang
dict=${newlangdir}/dict
dict_tmp=${newlangdir}/dict_tmp
graph=${newlangdir}/graph

# Make lexiconp.txt from lexicon.txt.
# Compile the word lexicon, L.fst.
echo "$0: prepare_lang"
if [ $dict_src/lexiconp.txt -ot $dict_src/lexicon.txt ]; then
  rm $dict_src/lexiconp.txt
fi
utils/prepare_lang.sh --phone-symbol-table $phones_src $dict_src "<unk>" $dict_tmp $dict
 
# Create the grammar/language model, G.fst.
echo "$0: ngram-count"
ngram-count -text $lang/clean.txt -order 3 -limit-vocab -vocab $dict_src/words.txt -kndiscount -interpolate -lm $lm_src
gzip $lm_src
echo "$0: format_lm"
utils/format_lm.sh $dict $lm_src.gz $dict_src/lexicon.txt $lang
 
# Assemble the HCLG graph.
echo "$0: mkgraph"
utils/mkgraph.sh --self-loop-scale 1.0 $lang $model $graph
 
# To use this newly created model, also build a decoding configuration.
# Put these into the directory ${newlangdir}/conf.
echo "$0: prepare_online_decoding"
steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf $lang exp/nnet3/extractor exp/chain/tdnn_7b ${newlangdir}

# It doesn't matter that these last two steps are reversed from https://chrisearch.wordpress.com/2017/03/11/speech-recognition-using-kaldi-extending-and-using-the-aspire-model.
