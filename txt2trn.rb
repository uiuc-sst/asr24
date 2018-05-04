#!/usr/bin/env ruby

# Convert conventional transcriptions to TRN format for scoring by sclite -r trn,
# http://www1.icsi.berkeley.edu/Speech/docs/sctk-1.2/options.htm
#
# Usage:
# ./txt2trn.rb < arabic-ref.txt > arabic-ref.trn.txt
# ./txt2trn.rb < arabic-scrips.txt > arabic-scrips.trn.txt

# Each input line is an utterance: id, whitespace, words.
# Each output line is words, whitespace, (id).

$stdin.each_line {|l|
  a = l.chomp.strip.split(/\s/)
  next if a.size < 2
  puts a[1..-2].join(' ') + ' (' + a[0] + ')'
}
