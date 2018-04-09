#!/bin/bash

module unload gcc/4.7.1 gcc/4.9.2
module load python/2 # Also loads gcc/6.2.0, says module show python/2
module unload gcc/6.2.0 # don't conflict with 7.2.0
module load gcc/7.2.0 # for GLIBCXX_3.4.23

. cmd.sh
. path.sh

# Create wav.scp, each line: uttid wavfile.
# Create utt2spk, each line: uttid uttid.
rm -f wav.scp; touch wav.scp
rm -f utt2spk; touch utt2spk
for f in /scratch/users/cog/tam.8khz/TAM_EVAL*; do echo $(basename ${f%.*}) "$f" >> wav.scp; echo $(basename ${f%.*}) $(basename ${f%.*}) >> utt2spk; done
