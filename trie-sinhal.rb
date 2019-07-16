#!/usr/bin/env ruby
# encoding: utf-8

# Usage: $0 < trie2-scrips.txt > sinhal-trie-scrips.txt
# The input is transcriptions made of nonsense English words.

$phoneFile = 'sinhal.g2p' # From /ws/ifp-53_1/hasegawa/tools/cog/g2ps-aspire/Sinhalese_wikipedia_symboltable.txt.
$g2p = File.readlines($phoneFile) .map {|s| s.downcase.chomp.split("\t")}
$phones = $g2p.map {|s| s[1].split(' ')} .flatten .sort .uniq
# $phones.each {|ph| puts ph}; exit 1

# Read transcriptions made of nonsense English words.
$scrips = ARGF.readlines .map {|s| s.split(' ')}

$prondict = File.readlines('trie2/train_all/cmudict-plain.txt') \
  .map {|s| s.downcase.chomp.split("\t") } \
  .delete_if {|s| /[a-z]/ !~ s[0][0]}		# Omit words that begin with a nonletter.
$pd = {}
$prondict.each {|s| $pd[s[0]] = s[1]}
# $pd.each_pair {|k,v| puts k + '=' + v}; exit 1

$scrips.map! {|s| [s[0], s[1..-1].map {|w| $pd[w]}.join(' ')]}
# $scrips is an array of [uttid, phone string], e.g.
# ["IL9_SetE_046_041", "dh ey m ey d f ah n ah ..."].

# Convert each phone string into a word string, using a trie as in PTgen/steps/phone2word.rb.
Prondict = 'sinhal-lexicon.txt' # From a non-trie sinhal's local/dict/lexicon.txt.
require "trie" # gem install fast_trie (On ifp-53, append --user-install.)
trie = Trie.new
h =  Hash.new {|h,k| h[k] = []} # A hash mapping each pronunciation to an array of homonym words.
i = 0

# Restrict phones.  Map rare ones to common ones.  Map into the prondict.
$remap = Hash[ 
  'ae','ey', 'ay','ey', 'ao','uh', 'ah','aa',
  'ch','jh', 'b','p', 'ng','m'
]
def soft(ph) r = $remap[ph]; r ? r : ph; end

begin
  pd = File.readlines(Prondict) .map {|l| l.chomp.strip.downcase }
  pd.map! {|l| l =~ /\t/ ? l : l.sub(" ", "\t")}
  pd.map! {|l| l.split("\t") }
  pd.map! {|w,pron| [w.strip, pron.strip]}
  pd.uniq!
  # If we cull length-1 words, almost no words remain.  So instead soft-match aggressively.
  # Soft-match like Soundex.
  pd.map! {|w,pron| [w, pron.split(" ").map{|ph| soft(ph)}.join(" ")]}
  # Deduplicate phones.
  pd.map! {|w,pron| [w, pron.split(" ").chunk{|x|x}.map(&:first) .join(" ")]}
  pd.sort!; pd.uniq!
  pd.each {|w,p| trie.add p; i += 1 }
  pd.each {|w,p| h[p] << w }
  STDERR.puts "loaded #{i} pronunciations from prondict."
end
hNew = Hash.new
h.each {|pron,words| hNew[pron] = words }
h = hNew
# Now trie has all the pronunciations, and h has all the homonyms.
# File.open("/tmp/prondict-reconstituted.txt", "w") {|f| h.each {|pron,words| f.puts "#{pron}\t\t\t\t#{words.join(' ')}"} }

if false
  # To design $remap, this reports the phones' histogram,
  # so you can then map rare ones to common ones.
  histo = Hash.new {|h,k| h[k] = 0}
  h.each {|pron,words| pron.split(' ').each {|ph| histo[ph] += 1 }}
  histo.to_a.sort_by {|k,v| -v} .each {|ph,count| puts "#{ph}\t#{count}"}
  exit 1
end

# Convert transcriptions from phones to words.
$scrips.each {|uttid,phones|
  print uttid + "\t"
  if !phones
    puts
    next
  end
  phones = phones.split ' '
  prefix = ""
  prefixPrev = ""
  i = 0
  iStart = 0
  while i < phones.size
    foo = soft(phones[i])
    prefixPrev = prefix.rstrip
    prefix += foo + " "
    if trie.has_children?(prefix.rstrip)
      # Extend prefix.
      i += 1
      next
    end
    if trie.has_key? prefixPrev
      i = iStart = i+1
      words = h[prefixPrev]
      word = words[rand(words.size)]
      print " " + word + " "
    else
      c = prefixPrev.split(' ').size
      if c > 1
	prefixAgain = prefixPrev.split(' ')[0..-2].join(' ')
	if trie.has_key? prefixAgain
	  i = iStart = i+1 -2
	  words = h[prefixAgain]
	  word = words[rand(words.size)] # pick a homonym randomly
	  print " " + word + " "
	  prefix = ""
	  next
	end
      end
      # puts "\nSkipped #{phones[iStart]} -> #{soft(phones[iStart])}."
      # Usage: pipe this to: grep Skip|sort|uniq -c|sort -nr >> /tmp/z
      iStart = i = iStart+1
    end
    prefix = ""
  end
  puts
}
