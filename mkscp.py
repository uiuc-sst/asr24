#!/usr/bin/env python3

# Split a listing of jobs into num_jobs script files and spk2utt files, called
# lang/scp/\d\d.txt, lang/cmd/\d\d.sh, and lang/spk2utt/\d\d.txt.
# From dirWav, use only the .wav files; ignore other files.

import sys, glob, os, re, math

USAGE='''USAGE: mkscp.py wav_dir num_jobs lang_dir'''

if len(sys.argv) < 4 or not sys.argv[2].isdecimal():
    print(USAGE)
    exit(1)
dummy, dirWav, num_jobs, lang = sys.argv
num_jobs = int(num_jobs)
if num_jobs < 1:
    print(USAGE)
    exit(1)
if not os.path.exists(dirWav):
    print('mkscp.py: missing directory ' + dirWav)
    exit(1)

wavfiles = os.listdir(dirWav)
ids = [ re.sub(r'.*/', '', re.sub(r'\..*', '', x)) for x in wavfiles ]
if not ids:
    print('mkscp.py: no .wav files in directory ' + dirWav)
    exit(1)

if not os.path.exists(lang):
    os.mkdir(lang)
scp_base = lang + '/scp/'
if not os.path.exists(scp_base):
    os.mkdir(scp_base)
spk2utt_base = lang + '/spk2utt/'
if not os.path.exists(spk2utt_base):
    os.mkdir(spk2utt_base)
cmd_base = lang + '/cmd/'
if not os.path.exists(cmd_base):
    os.mkdir(cmd_base)
lat_base = lang + '/lat/'
if not os.path.exists(lat_base):
    os.mkdir(lat_base)

# Remove previously made files.
# DON'T remove lat_base/*, though.  Leave that until submit-foo.sh.
for f in glob.glob(scp_base + '*') + glob.glob(spk2utt_base + '*') + glob.glob(cmd_base + '*'):
    os.remove(f)

# Write slightly different files, depending on if this host has qsub or not.
# Python 3.3 has a better test, shutil.which(), but campuscluster's python3 is only 3.2.
import distutils.spawn
qsub = distutils.spawn.find_executable("qsub") != None

num_per_job = len(wavfiles)/num_jobs

basic_cmd = 'online2-wav-nnet3-latgen-faster --online=false --frame-subsampling-factor=3 --config={}/conf/online.conf --max-active=7000 --beam=15.0 --lattice-beam=6.0 --acoustic-scale=1.0 --word-symbol-table={}/graph/words.txt exp/tdnn_7b_chain_online/final.mdl {}/graph/HCLG.fst'.format(lang,lang,lang)

cmd_submit = lang + '-submit.sh'
with open(cmd_submit, 'w') as j:
    j.write('#!/usr/bin/env bash\n')
    j.write('rm -rf %s; mkdir %s\n' % (lat_base, lat_base))
    for n in range(0, num_jobs):
        scpfilename = '%s%2.2d.txt' % (scp_base, n)
        spk2uttfilename = '%s%2.2d.txt' % (spk2utt_base, n)
        with open(scpfilename, 'w') as f:
            with open(spk2uttfilename, 'w') as g:
                for m in range(math.ceil(n*num_per_job), min(len(wavfiles), math.ceil((n+1)*num_per_job))):
                    f.write('{}\t{}/{}\n'.format(ids[m], dirWav, wavfiles[m]))
                    g.write('{}\t{}\n'.format(ids[m], ids[m]))

        latfilename   = '%s%2.2d.lat'   % (lat_base, n)
#       nbestfilename = '%s%2.2d.nbest' % (lat_base, n)
#       wordsfilename = '%s%2.2d.words' % (lat_base, n)
#       asciifilename = '%s%2.2d.ascii' % (lat_base, n)
        logfilename   = '%s%2.2d.log'   % (lat_base, n)
        cmdfilename   = '%s%2.2d.sh'    % (cmd_base, n)
        with open(cmdfilename, 'w') as h:
            h.write('. cmd.sh\n. path.sh\n')
            if qsub:
                h.write('module unload gcc/4.7.1 gcc/4.9.2\nmodule load python/2\nmodule swap gcc/6.2.0 gcc/7.2.0\n')
                # "module show python/2" also loads gcc/6.2.0.
                # Then swap that with gcc/7.2.0, for GLIBCXX_3.4.23.
            h.write("{} 'ark:{}' 'scp:{}' 'ark:{}' 2> {}\n".format(basic_cmd, spk2uttfilename, scpfilename, latfilename, logfilename))
#           h.write("lattice-to-nbest --acoustic-scale=0.1 --n=9 'ark:{}' 'ark:{}'\n".format(latfilename, nbestfilename))
#           h.write("nbest-to-linear 'ark:{}' ark:/dev/null 'ark,t:{}' ark:/dev/null ark:/dev/null\n".format(nbestfilename, wordsfilename))
#           h.write("utils/int2sym.pl -f 2- {}/graph/words.txt < {} > {}\n".format(lang, wordsfilename, asciifilename))
        os.chmod(cmdfilename, 0o775)
        if qsub:
            j.write('qsub -q secondary -d $PWD -l nodes=1 {}\n'.format(cmdfilename))
        else:
            j.write('{} &\n'.format(cmdfilename))
    if qsub:
        j.write('qstat -u cog\n')
os.chmod(cmd_submit, 0o775)
