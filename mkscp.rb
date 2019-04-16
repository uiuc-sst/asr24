#!/usr/bin/env ruby
# encoding: utf-8

# Port of mkscp.py.

# Split a listing of jobs into num_jobs script files and spk2utt files, called
# lang/scp/\d\d.txt, lang/cmd/\d\d.sh, and lang/spk2utt/\d\d.txt.
# From dirWav, use only the .wav files; ignore other files.

require 'fileutils'

Usage = "USAGE: mkscp.py wav_dir num_jobs lang_dir"
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

$wavs = Dir.glob($dirWav + "/*.wav") .map {|f| File.basename(f)}
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

$cmd_submit = $lang + '-submit.sh'
File.open($cmd_submit, "w") {|j|
  j.puts "#!/usr/bin/env bash\nrm -rf #$lat_base; mkdir #$lat_base"
  $numJobs.times {|n|
    $scpfilename     =     "#$scp_base#{'%2.2d' % n}.txt"
    $spk2uttfilename = "#$spk2utt_base#{'%2.2d' % n}.txt"
    File.open($scpfilename, "w") {|f|
      File.open($spk2uttfilename, "w") {|g|
	((n*$num_per_job).ceil ... [((n+1)*$num_per_job).ceil, $wavs.size].min).each {|m|
	  f.puts "#{$ids[m]}\t#$dirWav/#{$wavs[m]}"
	  g.puts "#{$ids[m]}\t#{$ids[m]}"
	}
      }
    }
    $latfilename   = "#$lat_base#{'%2.2d' % n}.lat"
    $nbestfilename = "#$lat_base#{'%2.2d' % n}.nbest"
#   $wordsfilename = "#$lat_base#{'%2.2d' % n}.words"
#   $asciifilename = "#$lat_base#{'%2.2d' % n}.ascii"
    $logfilename   = "#$lat_base#{'%2.2d' % n}.log"
    $cmdfilename   = "#$cmd_base#{'%2.2d' % n}.sh"
    File.open($cmdfilename, "w") {|h|
      h.puts ". cmd.sh\n. path.sh\n"
      h.puts "module unload gcc/4.7.1 gcc/4.9.2\nmodule load python/2\nmodule swap gcc/6.2.0 gcc/7.2.0\n" if qsub
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
exit 0
