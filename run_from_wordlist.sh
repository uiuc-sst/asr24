#!/usr/bin/env bash

# Input files come from Gina.
# Copy LANG_arpa.lm.gz to LANG/lang/lm.arpa.gz.
# Copy LANG_unigrams.txt(.gz) to LANG/local/dict/words.txt.
# Then run this script.

# Run each stage.

if [ $# != 1 ]; then
  echo "Usage: $0 <newlangdir>" # e.g., $0 tamil, or $0 russian.
  exit 1
fi
[ ! -d $1 ] && echo "$0: missing directory $1. Aborting." && exit 1

./mkprondict_from_wordlist.py $1 || exit 1
./newlangdir_make_graphs_from_wordlist.sh $1 || exit 1
./newlangdir_make_confs.sh  $1 || exit 1
