#!/usr/bin/env ruby

# On ifp-53, copy this script to ~/l/wer-prep.rb.
# On ifp-serv-03, run it: ~/53/eval/prep-wer.rb | sort > ~/53/assam-ref.txt
# On ifp-53, copy the result: mv ~/l/assam-ref.txt .

[ '/ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Assamese/LDC2016E02/scripted/training/transcription/*.txt',
  '/ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Assamese/LDC2016E02/conversational/*/transcription/*.txt'].each {|dir|
  Dir.glob(dir) {|f|
    # Read every second line, chomp off the newline, join into one line, strip noise, compactify whitespace.
    scrip = File.readlines(f) .drop(1).each_slice(2).map(&:first) .map(&:chomp) .join(' ') \
      .gsub('<no-speech>', ' ') \
      .gsub('<int>', '<INT>') \
      .gsub('<hes>', '<HES>') \
      .gsub('<sta>', '<STA>') \
      .gsub('<laugh>', '<LAUGH>') \
      .gsub('(())', ' ') \
      .gsub(/ [ ]*/, ' ')

    puts File.basename(f, ".txt") + ' ' + scrip
  }
}
