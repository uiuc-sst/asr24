#!/usr/bin/env ruby
# encoding: utf-8

# Like compute-wer, but with inputs downcased.

if ARGV.size < 2
  STDERR.puts "Usage: #$0 [args] ark:ref.txt ark:hyp.txt, like Kaldi's compute-wer."
  exit 1
end
$args = ARGV[0...-2].join ' '
$ref = ARGV[-2]
$hyp = ARGV[-1]

# Strip <tags>.
# Decapitalize.
# De-accent letters.
# Convert most punctuation to whitespace.
# Coalesce repeated spaces; strip leading/trailing whitespace.
# Remove ’ ONLY if at the start or end, where it's a quote mark, not a kw’izina.
# Hope that all that filtering didn't mangle the leading uttid's to have duplicates.
class Array
  def normalize() self \
    .map {|w| w  .gsub(/<[^>]+>/, '') .gsub('(())', '')} \
    .map(&:downcase) \
    .map {|w| w .gsub(/[èé]/, 'e') .gsub(/ï/, 'i') .gsub(/[ !"&'\(\)\,\-\.\/\:;>?@\[\]«–‘“”…]/, ' ') .gsub(/ [ ]*/, ' ')} \
    .map(&:strip) \
    .map {|w| w .sub(/^’/, '') .sub(/’$/, '') } \
    .map {|w| w.gsub(/[ ]+/, ' ')}
  end
end

$wRef = File.readlines($ref[4..-1]).normalize
$wHyp = File.readlines($hyp[4..-1]).normalize

$refTmp = "/tmp/ref"
$hypTmp = "/tmp/hyp"
File.open($refTmp, "w") {|f| $wRef.each {|l| f.puts l}}
File.open($hypTmp, "w") {|f| $wHyp.each {|l| f.puts l}}

puts `../../../src/bin/compute-wer #$args ark:#$refTmp ark:#$hypTmp`[1..-1]
