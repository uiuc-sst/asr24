#!/usr/bin/env ruby
# encoding: utf-8

# Compute a WER that normalizes variant spelling.

if ARGV.size == 0
  $ref = "somali-NI-transcriptions8.txt"
  $hyp = "somali8/scrips.txt"
  STDERR.puts "Using default input files."
elsif ARGV.size == 2
  $ref,$hyp = ARGV
  STDERR.puts "Usage: #$0 ref.txt hyp.txt"
  STDERR.puts "ref.txt and hyp.txt have lines: utterance-id, whitespace, transcription."
  exit 1
end

# Build a word list from ref and hyp.
# Skip the leading utterance-id.
# Remove duplicates.

wordsRaw = (File.readlines($ref) + File.readlines($hyp)) \
  .map {|l| l.split(/\s/)[1..-1]} .flatten .sort .uniq

def vowel?(c) "aeiou".include?(c) end	# y is special for our purposes.
def lr?(c) "lr".include?(c) end
def nasal?(c) "mn".include?(c) end
def apostr?(c) " '’".include?(c) end

# Decapitalize.
# De-accent letters.
# Convert most punctuation to whitespace.
# Coalesce repeated spaces; strip leading/trailing whitespace.
# Remove ’ and ' ONLY if at the start or end, where it's more likely a quote mark than a glottal stop.

wordsCooked = wordsRaw
  .map(&:downcase) \
  .map {|w| w .gsub(/[èé]/, 'e') .gsub(/ï/, 'i') .gsub(/[ !"&\(\)\,\-\.\/\:;>?@\[\]«–‘“”…]/, ' ') .gsub(/ [ ]*/, ' ')} \
  .map(&:strip) \
  .map {|w| w .sub(/^['’]/, '') .sub(/['’]$/, '') }

# Remove doubled vowels from non-short words.
wordsCooked.map! {|w| w.size <= 5 ? w :
  w.gsub('aa', 'a') .gsub('ee', 'e') .gsub('ii', 'i') .gsub('oo', 'o') .gsub('uu', 'u') }

# todo: If two long words differ only in a m/n/ng, or x/h, or a vowel, or y-between-vowels, consider them synonyms.

# todo: Also replace raw Doodda-gaaban, cooked doodda gaaban, with dooddagaaban?

# The map from raw words to normalized words.
$wordMap = [wordsRaw, wordsCooked].transpose
#$wordMap.each {|w| puts w.inspect if / / =~ w[1]} # Do any words have spaces?  Then it's really several words.
hash = {}
$wordMap.each {|raw,cooked| hash[raw] = cooked}
$wordMap = hash

STDERR.puts "Distinct raw words: #{wordsRaw.size}"
words = wordsCooked.uniq.select {|w| w.size > 5}
STDERR.puts "Long words: #{words.size}"

wordsRaw.freeze
wordsCooked.freeze
words.freeze
$wordMap.freeze

def lookup(w)
  w1 = $wordMap[w]
  return w if !w1
  return w1
end
ref = File.readlines($ref).map {|l| l.split(/\s/).map{|w| lookup(w)}}
hyp = File.readlines($hyp).map {|l| l.split(/\s/).map{|w| lookup(w)}}

$refTmp = "/tmp/ref"
$hypTmp = "/tmp/hyp"
File.open($refTmp, "w") {|f| ref.each {|l| f.puts(l.join(' '))}}
File.open($hypTmp, "w") {|f| hyp.each {|l| f.puts(l.join(' '))}}
puts `../../../src/bin/compute-wer --mode=present --verbose=1 ark:#$refTmp ark:#$hypTmp`
