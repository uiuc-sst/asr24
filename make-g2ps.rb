#!/usr/bin/env ruby

# Convert IPA g2p's to Aspire g2p's.

G2PS = '/tmp/g2ps' # In the parent dir (/tmp), do: git clone https://github.com/uiuc-sst/g2ps.git
$out = '/tmp/g2ps-aspire'
`mkdir -p #$out`

Dir.glob(G2PS + '/*/*_wikipedia_symboltable.txt') {|f|
  if File.basename(f) == 'Thai_wikipedia_symboltable.txt'
    STDERR.puts "#$0: skipping non-g2p Thai_wikipedia_symboltable.txt."
    next
  end
  $fileErr = $out + '/' + File.basename(f, 'txt') + 'err'
  `./g2ipa2asr.py #{f} aspire2ipa.txt phoibletable.csv 2> #$fileErr | sort -u > #$out/#{File.basename(f)}`
  $err = `sort -u < #$fileErr`
  puts File.basename(f) + ":\n" + $err + "\n" if !$err.empty?
}
