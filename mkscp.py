#!/usr/bin/env python3
import sys
import os
import re
import math

USAGE='''USAGE: mkscp.py data_dir num_jobs lang
  Split a listing of jobs into num_jobs script files and spk2utt files, called
  lang/scp/\d\d.txt, lang/cmd/\d\d.sh, and lang/spk2utt/\d\d.txt.
  Uses only the .wav files in data_dir; other files ignored.'''

if len(sys.argv) < 4 or not sys.argv[2].isdigit():
    print(USAGE)
    exit(0)

data_dir = sys.argv[1]
num_jobs = int(sys.argv[2])
lang = sys.argv[3]
scp_base = lang + '/scp/'
if not os.path.exists(scp_base):
    os.mkdir(scp_base)
spk2utt_base = lang + '/spk2utt/'
if not os.path.exists(spk2utt_base):
    os.mkdir(spk2utt_base)
cmd_base = lang + '/cmd/'
if not os.path.exists(cmd_base):
    os.mkdir(cmd_base)

basic_command = 'online2-wav-nnet3-latgen-faster --online=false --frame-subsampling-factor=3 --config={}/conf/online.conf --max-active=7000 --beam=15.0 --lattice-beam=6.0 --acoustic-scale=1.0 --word-symbol-table={}/graph/words.txt exp/tdnn_7b_chain_online/final.mdl {}/graph/HCLG.fst'.format(lang,lang,lang)

wavfiles = os.listdir(data_dir)
ids = [ re.sub(r'.*/','',re.sub(r'\..*','',x)) for x in wavfiles ]
num_per_scp = len(wavfiles)/num_jobs

for n in range(0,num_jobs):
    scpfilename = '%s%s%2.2d.txt' % (scp_base, lang, n)
    spk2uttfilename = '%s%s%2.2d.txt' % (spk2utt_base, lang, n)
    cmdfilename = '%s%s%2.2d.sh' % (cmd_base, lang, n)
    with open(scpfilename,'w') as f:
        with open(spk2uttfilename,'w') as g:
            for m in range(math.ceil(n*num_per_scp),min(len(wavfiles),math.ceil((n+1)*num_per_scp))):
                f.write('{}\t{}/{}\n'.format(ids[m],data_dir,wavfiles[m]))
                g.write('{}\t{}\n'.format(ids[m],ids[m]))

    with open(cmdfilename,'w') as h:
        command = "{} 'ark:{}' 'scp:{}' 'ark:/dev/null'\n".format(basic_command, spk2uttfilename,  scpfilename)
        h.write('. cmd.sh\n')
        h.write('. path.sh\n')
        h.write(command)
