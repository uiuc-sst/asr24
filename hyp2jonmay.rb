#!/usr/bin/env ruby
# encoding: utf-8

# On stdin, read lines that are uttid, tab, transcription.
# Write the single text file $jonmay,
# the dir of utterance-files jonmaydir,
# and an XML file to sftp to Jon May.

# Mostly copied from https://github.com/uiuc-sst/PTgen's steps/hyp2jonmay.rb.

if ARGV.size != 3
  STDERR.puts "Usage: #$0 jonmay_dir three_letter_language_code versionNumber < transcriptions.txt"
  exit 1
end
$jonmaydir = ARGV[0]

$sourceLanguage = ARGV[1].upcase
$langForJon = $sourceLanguage.downcase
$version = ARGV[2] # e.g., 1, 2, ...

`rm -rf #$jonmaydir; mkdir #$jonmaydir`
$stdin.set_encoding(Encoding::UTF_8).each_line {|l|
  uttid,scrip = l.split "\t"
  if !uttid
    STDERR.puts "#$0: expected uttid, tab, transcription in input line '#{l}'."
    next
  end
  File.open("#$jonmaydir/#{uttid}.txt", "w") {|f| f.puts scrip}
}

$tojon = "elisa.#{$langForJon}-eng.eval-asr-uiuc-s#$version.y4r1.v1.xml"

STDERR.puts `./flat2elisa.py -i #$jonmaydir -l #$langForJon -o #$tojon`
`rm -rf #$tojon.gz #$jonmaydir; gzip --best #$tojon`
STDERR.puts "Please sftp to Jon the file #$tojon.gz"
