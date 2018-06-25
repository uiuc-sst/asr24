#!/usr/bin/env ruby

# Convert IPA g2p's to Aspire g2p's.
# This takes 10 seconds.

G2PS = '/tmp/g2ps'
if !Dir.exist?(G2PS)
  # This takes 15 seconds.
  `cd #{File.dirname(G2PS)} && git clone https://github.com/uiuc-sst/g2ps.git`
else
  `cd #{G2PS} && git pull`
end

$out = '/tmp/g2ps-aspire'
`mkdir -p #$out; rm -rf #$out/*`

Dir.glob(G2PS + '/*/*_wikipedia_symboltable.txt') {|f|
  if File.basename(f) == 'Thai_wikipedia_symboltable.txt'
    STDERR.puts "#$0: skipping non-g2p Thai_wikipedia_symboltable.txt."
    next
  end
  $fileErr = $out + '/' + File.basename(f, 'txt') + 'err'
  `./g2ipa2asr.py #{f} aspire2ipa.txt #{G2PS}/_config/phoibletable.csv 2> #$fileErr | sort -u > #$out/#{File.basename(f)}`
  $err = `sort -u < #$fileErr`
  if $err.empty?
    File.delete $fileErr
  else
    puts File.basename(f) + ":\n" + $err + "\n"
  end
}
