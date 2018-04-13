#!/usr/bin/env bash

# Compose an IL LG.fst with Aspire's HC.fst, to make an HCLG.fst.
# Output is ${newlangdir}/local/lm/3gram-mincount/lm_unpruned.gz 
# Works on Mac and campus cluster.
# (Originally in s5/local, run from s5.)

if [ $# != 1 ]; then
  echo "Usage: $0 <newlangdir>"
  echo "Inputs and outputs are all in <newlangdir>."
  echo "Inputs: local/dict/lexicon.txt, train_all/text."
  echo "Intermediate outputs: local/lm/{text.no_oov, word.counts, unigram.counts, word_map, train.gz, wordlist.mapped"
  echo "Output: local/lm/3gram-mincount/lm_unpruned.gz." # Or 3gram-mincount/{ngrams.gz, heldout_ngrams.gz, configs, perplexities}?
  exit 1
fi
[ ! -d $1 ] && echo "$0: missing directory $1. Aborting." && exit 1
newlangdir=$1

text=${newlangdir}/train_all/text
lexicon=${newlangdir}/local/dict/lexicon.txt 
for f in "$text" "$lexicon"; do
  [ ! -f $f ] && echo "$0: missing file $f. Aborting." && exit 1
done

export LC_ALL=C # This locale avoids errors about things being not sorted.
export PATH=$PATH:`pwd`/../../../tools/kaldi_lm
( cd ../../../tools || exit 1
  if [ ! -d kaldi_lm ]; then
    if [ ! -f kaldi_lm.tar.gz ]; then
      echo Downloading and installing the kaldi_lm tools.
      wget http://www.danielpovey.com/files/kaldi/kaldi_lm.tar.gz || exit 1
    fi
    tar xzf kaldi_lm.tar.gz || exit 1
    cd kaldi_lm
    make || exit 1
    echo Installed the kaldi_lm tools.
  fi
) || exit 1

dir=${newlangdir}/local/lm
mkdir -p $dir
cleantext=$dir/text.no_oov
tmp=$dir/tmp

awk -v lex=$lexicon 'BEGIN{while((getline<lex) >0){ seen[$1]=1; } } 
  {for(n=1; n<=NF;n++) { if (seen[$n]) { printf("%s ", $n); } else {print("<unk> ");} } print("\n");}' \
  < $text > $cleantext || exit 1

rm -rf $tmp
awk '{for(n=2;n<=NF;n++) print $n; }' < $cleantext | tee $tmp \
  sort | uniq -c | sort -nr > $dir/word.counts || exit 1

# Get counts from acoustic training transcripts.
# Add one-count for each word in the lexicon except silence
# (silence is added to the LM optionally, later).
cat $tmp <(grep -w -v '!SIL' $lexicon | awk '{print $1}') | \
  sort | uniq -c | sort -nr > $dir/unigram.counts || exit 1
rm -rf $tmp

# We probably won't use <unk>, because there aren't any OOVs.
awk '{print $2}' < $dir/unigram.counts | get_word_map.pl "<s>" "</s>" "<unk>" > $dir/word_map \
  || exit 1

# Ignore train.txt's first field, the utterance-id.
awk -v wmap=$dir/word_map 'BEGIN{while((getline<wmap)>0)map[$1]=$2;}
  { for(n=2;n<=NF;n++) { print map[$n]; if(n<NF){ print " "; } else { print ""; }}}' \
  < $cleantext | gzip -c > $dir/train.gz || exit 1

train_lm.sh --arpa --lmtype 3gram-mincount $dir || exit 1
# Or --lmtype 4gram-mincount.

# Perplexity over 88307.000000 words (excluding 691.000000 OOVs) is 71.241332
