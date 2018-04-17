#!/usr/bin/env bash

# Train an IL language model,
# from a pronunciation dictionary local/dict/lexicon.txt
# and a file of lines of text train_all/text.
#
# Works on Mac, campus cluster, ifp-53.
# Takes about a minute, on 100k words.  Not multicore.
# (Originally in s5/local, run from s5.)

if [ $# != 1 ]; then
  echo "Usage: $0 <newlangdir>" # e.g., $0 tamil, or $0 russian.
  echo "Inputs and outputs are all in <newlangdir>."
  echo "Inputs: local/dict/lexicon.txt, train_all/text."
  # Intermediate outputs: local/lm/{text.no_oov, word.counts, unigram.counts, word_map, train.gz, wordlist.mapped}
  echo "Output: local/lm/3gram-mincount/lm_unpruned.gz."
  # Output, from train_lm.sh at the end of this script, also includes
  # local/lm/3gram-mincount/{ngrams.gz, heldout_ngrams.gz, ngrams_disc.gz, configs, perplexities, ...}.
  exit 1
fi
[ ! -d $1 ] && echo "$0: missing directory $1. Aborting." && exit 1
newlangdir=$1

text=$newlangdir/train_all/text
lexicon=$newlangdir/local/dict/lexicon.txt
for f in "$text" "$lexicon"; do
  [ ! -f $f ] && echo "$0: missing file $f. Aborting." && exit 1
done

export LC_ALL=C # This locale avoids errors about things being not sorted.
export PATH=$PATH:$PWD/../../../tools/kaldi_lm
( cd ../../../tools || exit 1
  if [ ! -d kaldi_lm ]; then
    if [ ! -f kaldi_lm.tar.gz ]; then
      echo "$0: downloading and installing the kaldi_lm tools."
      wget http://www.danielpovey.com/files/kaldi/kaldi_lm.tar.gz || exit 1
    fi
    tar xzf kaldi_lm.tar.gz || exit 1
    cd kaldi_lm
    make || exit 1
    echo "$0: installed the kaldi_lm tools."
  fi
) || exit 1

dir=$newlangdir/local/lm
mkdir -p $dir
cleantext=$dir/text.no_oov
tmp=$dir/tmp
# In awk, print appends \n but printf doesn't.

echo "$0: building LM training data from $text and $lexicon."
awk -v lex=$lexicon 'BEGIN{ while((getline<lex) > 0) { seen[$1]=1; }}
  { for(n=1;n<=NF;n++) { printf("%s ", seen[$n] ? $n : "<unk>"); } print "";}' \
  < $text > $cleantext || exit 1

rm -rf $tmp
awk '{ for(n=2;n<=NF;n++) print $n; }' < $cleantext | tee $tmp |
  sort | uniq -c | sort -nr > $dir/word.counts || exit 1

# Get counts from acoustic training transcripts.
# Add one-count for each word in the lexicon except silence
# (silence is added to the LM optionally, later).
cat $tmp <(grep -w -v '!SIL' $lexicon | awk '{print $1}') |
  sort | uniq -c | sort -nr > $dir/unigram.counts || exit 1
rm -rf $tmp

# Build a word map from the unigram counts.
# We probably won't use <unk>, because there aren't any OOVs.
awk '{print $2}' < $dir/unigram.counts | get_word_map.pl "<s>" "</s>" "<unk>" \
  > $dir/word_map || exit 1

# Build the training data.
# Ignore $cleantext's first field, the utterance-id.
awk -v wmap=$dir/word_map 'BEGIN{ while((getline<wmap) > 0) map[$1]=$2; }
  { for(n=2;n<=NF;n++) { printf map[$n]; printf n<NF ? " " : "\n"; }}' \
  < $cleantext | gzip -c > $dir/train.gz || exit 1

echo "$0: running train_lm.sh."
rm -rf $dir/3gram-mincount # Force train_lm.sh to recalculate everything.
train_lm.sh --arpa --lmtype 3gram-mincount $dir || exit 1
# Or --lmtype 4gram-mincount.

# Mark:
# Perplexity over 88307.000000 words (excluding 691.000000 OOVs) is 71.241332
# Camille, Tamil:
# Perplexity over 96350.000000 words (excluding 14607.000000 OOVs) is 2171.406327
