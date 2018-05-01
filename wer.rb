#!/usr/bin/env ruby

wer = `~/kaldi/src/bin/compute-wer --text --mode=present ark:assam-ref.txt ark:assam-scrips.txt`
puts wer
