#!/usr/bin/env ruby
# encoding: utf-8

# Split a listing of jobs into num_jobs script files and spk2utt files, called
# lang/scp/\d\d.txt, lang/cmd/\d\d.sh, and lang/spk2utt/\d\d.txt.
# From dirWav, use only the .wav files; ignore other files.

require 'fileutils'

Usage = "USAGE: #$0 wav_dir num_jobs lang_dir"
if ARGV.size != 3 || ARGV[1] !~ /^\d+$/
  STDERR.puts Usage
  exit 1
end
$dirWav = ARGV[0].chomp("/")
$numJobs = ARGV[1].to_i
$lang = ARGV[2].chomp("/")
if $numJobs < 1
  STDERR.puts Usage
  exit 1
end

$wavs = Dir.glob($dirWav + "/*.wav")
if $wavs.empty?
  STDERR.puts "#$0: no .wav files in directory #$dirWav"
  exit 1
end
$ids = $wavs.map {|f| File.basename(f, ".wav")}

def mkdir(d)
  Dir.mkdir d if !File.directory? d
end
mkdir $lang
$scp_base = $lang + "/scp/"; mkdir $scp_base
$spk2utt_base = $lang + "/spk2utt/"; mkdir $spk2utt_base
$cmd_base = $lang + "/cmd/"; mkdir $cmd_base
$lat_base = $lang + "/lat/"; mkdir $lat_base

# Remove previously made files, but don't remove lat_base/* until submit-lang.sh.
( Dir.glob($scp_base+'*') + \
  Dir.glob($spk2utt_base+'*') + \
  Dir.glob($cmd_base+'*'))
    .each {|f| File.delete f}

# Like bash's "which."
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each {|path|
    exts.each {|ext|
      exe = File.join path, cmd+ext
      return exe if File.executable?(exe) && !File.directory?(exe)
    }
  }
  return nil
end
# Write different commands if this host has qsub.
qsub = (which 'qsub') != nil

$num_per_job = $wavs.size.to_f / $numJobs
$basic_cmd = "online2-wav-nnet3-latgen-faster --online=false --frame-subsampling-factor=3 \
  --config=#$lang/conf/online.conf --max-active=7000 --beam=15.0 --lattice-beam=6.0 \
  --acoustic-scale=1.0 --word-symbol-table=#$lang/graph/words.txt \
  exp/tdnn_7b_chain_online/final.mdl #$lang/graph/HCLG.fst"

# Measure byte length of each wav.
$lens = $wavs.map {|f| File.size(f)}

# Distribute indexes of .wav's into $numJobs bins.
$bins = Array.new($numJobs) {[]}
if true

  FIXNUM_MAX =  (2**(0.size*8 - 2) - 1)
  FIXNUM_MIN = -(2**(0.size*8 - 2))
  wavsUnassigned = (0...$wavs.size).to_a

  while !wavsUnassigned.empty?
    # Of the unassigned wavs, find the longest one.
    iwavLongest = -1
    lenMax = 0
    wavsUnassigned.each {|iWav| 
      if $lens[iWav] > lenMax
	lenMax = $lens[iWav]
	iwavLongest = iWav
      end
    }
    # Find the least-full bin.
    iBinEmptiest = -1
    lenMin = FIXNUM_MAX
    $bins.each_with_index {|b,iBin|
      if b.empty?
	iBinEmptiest = iBin
	break # Trivially the least full.
      end
      len = b.map {|iWav| $lens[iWav]} .inject('+')
      if len < lenMin
	lenMin = len
	iBinEmptiest = iBin
      end
    }
    # Move iwavLongest from wavsUnassigned to $bins[iBinEmptiest].
    $bins[iBinEmptiest] << iwavLongest
    wavsUnassigned.delete iwavLongest
  end
  # For Somali, the resulting bin lengths vary by only 2%.
else
  # For Somali, the resulting bin lengths vary by 3700%.
  $numJobs.times {|i|
    ((i*$num_per_job).ceil ... [((i+1)*$num_per_job).ceil, $wavs.size].min).each {|m|
      $bins[i] << m
    }
  }
end
$bins.freeze
# $bins.each {|b| puts "#{b.map {|iWav| $lens[iWav]} .inject('+')} bytes, #{b.size} elements."}; exit 0

$cmd_submit = $lang + '-submit.sh'
File.open($cmd_submit, "w") {|j|
  j.puts "#!/usr/bin/env bash\nrm -rf #$lat_base; mkdir #$lat_base"
  $numJobs.times {|i|
    $i = '%2.2d' % i
    $scpfilename     =     "#$scp_base#$i.txt"
    $spk2uttfilename = "#$spk2utt_base#$i.txt"

    File.open($scpfilename, "w") {|f|
      $bins[i].each {|m| f.puts "#{$ids[m]}\t#{$wavs[m]}"}
    }
    File.open($spk2uttfilename, "w") {|f|
      $bins[i].each {|m| f.puts "#{$ids[m]}\t#{$ids[m]}"}
    }

#   $wordsfilename = "#$lat_base#$i.words"
#   $asciifilename = "#$lat_base#$i.ascii"
    $latfilename   = "#$lat_base#$i.lat"
    $nbestfilename = "#$lat_base#$i.nbest"
    $logfilename   = "#$lat_base#$i.log"
    $cmdfilename   = "#$cmd_base#$i.sh"
    File.open($cmdfilename, "w") {|h|
      h.puts ". cmd.sh; . path.sh"
      h.puts "module unload gcc/4.7.1 gcc/4.9.2\nmodule load python/2\nmodule swap gcc/6.2.0 gcc/7.2.0" if qsub
      h.puts "#$basic_cmd 'ark:#$spk2uttfilename' 'scp:#$scpfilename' 'ark:#$latfilename' 2> #$logfilename"
#     h.puts "lattice-to-nbest --acoustic-scale=0.1 --n=9 'ark:#$latfilename' 'ark:#$nbestfilename'"
#     h.puts "nbest-to-linear 'ark:#$nbestfilename' ark:/dev/null 'ark,t:#$wordsfilename ark:/dev/null ark:/dev/null"
#     h.puts "utils/int2sym.pl -f 2- #$lang/graph/words.txt < #$wordsfilename > #$asciifilename"
    }
    FileUtils.chmod 0775, $cmdfilename
    j.puts qsub ?
      "qsub -q secondary -d $PWD -l nodes=1 #$cmdfilename" :
      "#$cmdfilename &"
  }
  j.puts "qstat -u cog" if qsub
}
FileUtils.chmod 0775, $cmd_submit
