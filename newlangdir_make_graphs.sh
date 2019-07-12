#!/usr/bin/env bash

# Make an IL L.fst and G.fst.  Compose them with an HC.fst, to make an HCLG.fst.
# Run this on ifp-53, because campus cluster lacks a UTF-8-compatible perl needed by utils/validate_dict_dir.pl, called by utils/prepare_lang.sh.
# (Runs on a Mac in a few hours.  Much faster than Sequitur, a full weekend.)
# Runs Tamil on ifp-53 singlecore in 13 minutes.
# Example inputs and outputs are /scratch/users/jhasegaw/kaldi/egs/aspire/s5/{russian,tamil} (5 GB and 1 GB).

if [ $# != 1 ]; then
  echo "Usage: $0 <newlangdir>" # e.g., $0 tamil, or $0 russian.
  echo "Inputs and outputs are all in <newlangdir>."
  echo "Inputs: lang/clean.txt, local/dict/lexicon.txt, local/dict/words.txt."
  # Intermediate outputs: lang/topo == dict.topo (from prepare_lang.sh);
  #                       local/dict/lexiconp.txt; dict/L.fst == lang/L.fst; lang/G.fst; lang/lm.arpa.gz.
  echo "Output: graph/HCLG.fst"
  echo "SRILM must be in your path."
  exit 1
fi
[ ! -d $1 ] && echo "$0: missing directory $1. Aborting." && exit 1
newlangdir=$1

# Set up environment variables.
. cmd.sh || exit 1
. path.sh || exit 1

command -v ngram-count 1>/dev/null 2>&1 || { echo "$0: failed to find SRILM tools. Install SRILM and update path.sh."; exit 1; }
# If you get that error, do this: cd kaldi/tools; ./install_srilm.sh; follow its instructions.

# Input files and dirs.
model=exp/tdnn_7b_chain_online
phones_src=$model/phones.txt
dict_src=$newlangdir/local/dict
lang=$newlangdir/lang
 
# Dirs of intermediate files and output files.
dict=$newlangdir/dict		# Made by prepare_lang.sh.
dict_tmp=$newlangdir/dict_tmp	# Made by prepare_lang.sh.
graph=$newlangdir/graph		# Made by mkgraph.sh.

# Intermediate files.
lm_src=$lang/lm.arpa

[ ! -d $lang ] && echo "$0: missing directory $lang. Aborting." && exit 1
[ ! -f $lang/clean.txt ] && echo "$0: missing file $lang/clean.txt. Aborting." && exit 1
[ ! -d $dict_src ] && echo "$0: missing directory $dict_src. Aborting." && exit 1
[ ! -f $dict_src/lexicon.txt ] && echo "$0: missing file $dict_src/lexicon.txt. Aborting." && exit 1
[ ! -f $dict_src/words.txt ] && echo "$0: missing file $dict_src/words.txt. Aborting." && exit 1
[ ! -d $model ] && echo "$0: missing directory $model. Aborting." && exit 1
[ ! -f $phones_src ] && echo "$0: missing file $phones_src. Aborting." && exit 1
[ ! -f nonsilence_phones.txt ] && echo "$0: missing file nonsilence_phones.txt. Aborting." && exit 1
echo "$0: prepare_lang"
# Make some files.
echo "sil laughter noise oov" > $dict_src/extra_questions.txt
echo "sil" > $dict_src/optional_silence.txt
cat << EOF > $dict_src/silence_phones.txt
sil
laughter
noise
oov
EOF
cp nonsilence_phones.txt $dict_src

# Make lexiconp.txt from lexicon.txt.
# Also make the word lexicon, L.fst.
if [ $dict_src/lexiconp.txt -ot $dict_src/lexicon.txt ]; then
  # It might not have been created yet.
  rm -f $dict_src/lexiconp.txt
fi
utils/prepare_lang.sh --phone-symbol-table $phones_src $dict_src "<unk>" $dict_tmp $dict || exit 1
# (Sometimes the tamil/dict/words.txt built by prepare_lang.sh lacks a line for <unk>,
# so to fix that I added a few lines into utils/prepare_lang.sh,
# just before the line that defiles silphone:
#     word_count=`tail -n 1 $dir/words.txt | awk '{ print $2 }'`
#     echo "<unk>" | awk -v WC=$word_count '{ printf("%s %d\n", $1, ++WC); }' >> $dir/words.txt
 
# Make $lm_src.gz.
echo "$0: ngram-count"
# When using a trie, omit -kndiscount.
ngram-count -text $lang/clean.txt -order 3 -limit-vocab -vocab $dict_src/words.txt -kndiscount -interpolate -lm $lm_src || exit 1
gzip -f $lm_src
# Make the grammar/language model, $lang/G.fst, from the ARPA-format LM $lm_src.gz.
echo "$0: format_lm"
utils/format_lm.sh $dict $lm_src.gz $dict_src/lexicon.txt $lang || exit 1
 
# Make the HCLG graph, graph/HCLG.fst.
# Tamil's is 360 MB.
# Needs $lang/{L.fst, G.fst, phones.txt, words.txt, phones/silence.csl, phones/disambig.int}, $model/final.mdl, $model/tree
# Temporarily makes $lang/tmp/LG.fst, $lang/tmp/CLG_$N_$P.fst, graph/Ha.fst, graph/HCLGa.fst.
# Copies words.txt and phones/* from $lang to $graph.
echo "$0: mkgraph"
utils/mkgraph.sh --self-loop-scale 1.0 $lang $model $graph || exit 1
