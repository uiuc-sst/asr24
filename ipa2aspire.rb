#!/usr/bin/env ruby

# Filter for whitespace-delimited phone strings.
# Convert any IPA phones to Aspire ones, via table lookup.
# Pass through other phones, unchanged.
# Input can be STDIN or filenames on the command line.
# Called by phnrec.sh.

ipa2aspire = {}
open('aspire2ipa.txt', "r:ISO-8859-1:UTF-8") {|io|
  io.each {|x|
    x = x.chomp.split(/\s/)
    ipa2aspire[x[1]] = x[0]
  }
}
# ipa2aspire.each {|x| p x}

ARGF.set_encoding(Encoding::UTF_8).each_line {|l|
  l = l.chomp.split(/\s/)
  s = ''
  l.each {|ipa|
    out = ipa2aspire[ipa]
    s += out ? out : ipa
    s += ' '
  }
  puts s.rstrip
}
