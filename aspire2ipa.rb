#!/usr/bin/env ruby
# encoding: utf-8

# Convert Aspire phones to IPA, via table lookup,
# for a pronlex whose lines are whitespace-delimited word phone phone phone...
#
# For preparing a PTgen test/apply-LANG/data/langmodels/applyLANG/pronlex.txt.
# So the usage is: ./aspire2ipa.rb < tagalog/local/dict/lexicon.txt > ~/l/PTgen/test/apply-tgl/data/langmodels/applyTgl/pronlex.txt

# Input can be STDIN or filenames on the command line.
# Similar to ./ipa2aspire.rb.

aspire2ipa = {}
if false
  open('aspire2ipa.txt', "r:ISO-8859-1:UTF-8") {|io|
    io.each {|x|
      x = x.chomp.split(/\s/)
      aspire2ipa[x[0]] = x[1] # .encode('utf-8') has no effect
    }
  }
else
  # Desperate workaround for printing utf-8:  copy aspire2ipa.txt verbatim.
  # (You can't "include" a file into a heredoc, not even with #{load 'filename'}.)
  workaround = <<EOT
aa	ɑ
ae	æ
ah	ʌ
ao	ɔ
aw	aʊ
ay	aɪ
b	b
ch	tʃ
d	d
dh	ð
eh	ɛ
er	ɝ
ey	e
f	f
g	ɡ
hh	h
ih	ɪ
iy	i
jh	dʒ
k	k
l	l
m	m
n	n
ng	ŋ
ow	o
oy	ɔɪ
p	p
r	ɹ
s	s
sh	ʃ
t	t
th	θ
uh	ʊ
uw	u
v	v
w	w
y	j
z	z
zh	ʒ
EOT
  workaround.split("\n").each {|l| x = l.split(/\s/); aspire2ipa[x[0]] = x[1] }
end

ARGF.set_encoding(Encoding::UTF_8).each_line {|l|
  l = l.chomp.split(/\s/)
  print l[0] + "\t"
  s = ''.encode('utf-8')
  l[1..-1].each {|asp|
    out = aspire2ipa[asp]
    s += out ? out : asp
    s += ' '
  }
  puts s.strip
}
