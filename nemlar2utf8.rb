#!/usr/bin/env ruby
# coding: utf-8

# Convert asciified NEMLAR text back into Arabic script,
# as found in /ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Arabic/NEMLAR_speech/NMBCN7AR/DOC/DESIGN.DOC, pages 10-11.
#
# Typical input is /ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Arabic/NEMLAR_speech/NMBCN7AR/DOC/SUMMARY.TXT.
# To convert into a format suitable for ./wer.rb,
# nemlar2utf8.rb SUMMARY.TXT | sed -e 's/\r$//' -e 'N;s/\n/ /' -e 's/^\\NMBCN7AR\\DATA //' -e 's/.TRS//' | sort > arabic-ref.txt

if ARGV.length < 1 then
  STDERR.puts "USAGE: #$0 in.txt > out.txt"
  exit 1
end

open(ARGV[0], "r:ISO-8859-1:UTF-8") {|io|
  io.each {|x|
    unless x.match(/^\\/) then 
      # Strip NEMLAR noise that can't appear in a speech transcription.
      x.gsub! '&lt;', ' '
      x.gsub! '&gt;', ' '
      x.gsub! /[«»\,\:\;\.]/, ' '
      # Convert raw Arabic text.
      x.tr! '<>\'&}|{AYbtvjHxdgrzs$SpDTZcJfqklmnhwy', 'أإءؤئآٱاىبتثجحخدذرزسشصةضطظعغفقكلمنهوي'
      # Strip diacriticized text, which is rare in newspapers.
      x.gsub! /[aiuoFKN~]/, ''
      # Combine consecutive spaces.
      x.gsub!(/ [ ]*/, ' ')
    end
    puts x
  }
}
