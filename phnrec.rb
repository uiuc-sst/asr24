#!/usr/bin/env ruby
# encoding: utf-8

# After all phnrec's spawned by phnrec.py complete,
# merge the transcriptions they made, into $L/phn/IPA-scrips.txt.

if ARGV.length < 1 then
  STDERR.puts "USAGE: #$0 <newlangdir>" # e.g., $0 tamil
  exit 1
end
$L = ARGV[0]
# todo: check the existence of input files $L-8khz/*.rec and output dir $L/phn.

# Remove any previously created transcriptions.
`rm -rf #$L/phn/*.scr`

# Reformat each transcription.
Dir.glob("#$L-8khz/*.rec") {|f|
  uttid = File.basename(f, '.rec')
  scrip = $L + "/phn/" + uttid + ".scr"
  # Discard phnrec's timing info; keep only the phones.
  # Discard useless phones int,pau,spk.
  # Convert phones from SAMPA to IPA (*before* joining into one line,
  # because node.js javascript's readline notices input only after a newline!).
  # Hack: strip trailing _'s from phones (is that SAMPA)?
  # Hack: map unusual phones down to those in PTgen/mcasr/phones.txt.
  # Join phones into one line.
  # Store output in a tmp file "scrip" instead of a local variable, for more Ruby parallelism.
  `(echo -n #{uttid}; echo -n ' '; cut -f3 -d' ' #{f} | grep -Ev 'int|pau|spk' | ./sampa2ipa.js | tr -d _ |
  sed -e 's/ʋ/v/' -e 's/oː/o/' -e 's/eː/e/' |
  tr '\n' ' '; echo) > #{scrip} &`
  # This mangles the output: tr 'ʋ' 'v'
}

# Hack to wait for those threads.
# todo: wait until phn/*.scr has as many files as *.rec,
# or until no more ./sampa2ipa.js processes are running,
# and then a moment longer;
`sleep 3`

# Merge the transcriptions.
`cat #$L/phn/*.scr | sort > #$L/phn/IPA-scrips.txt;    rm -rf #$L/phn/*.scr`
