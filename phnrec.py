#!/usr/bin/env python3

# Given a dir of 8 kHz .wav files, convert each one into a string of IPA phones.
# By analogy with ./mkscp.py.
# ./phnrec.py $L-8khz $(nproc) $L

import sys, glob, os, re, math

USAGE='''USAGE: ./phnrec.py wav_dir num_jobs lang_dir'''

if len(sys.argv) < 4 or not sys.argv[2].isdecimal():
    print(USAGE)
    exit(1)
dummy, dirWav, num_jobs, lang = sys.argv
# todo: from dirWav and lang, strip any trailing slashes.
num_jobs = int(num_jobs)
if num_jobs < 1:
    print(USAGE)
    exit(1)
if not os.path.exists(dirWav):
    print('phnrec.py: missing directory ' + dirWav)
    exit(1)

wavfiles = os.listdir(dirWav)
ids = [ re.sub(r'.*/', '', re.sub(r'\..*', '', x)) for x in wavfiles ]
if not ids:
    print('phnrec.py: no .wav files in directory ' + dirWav)
    exit(1)

if not os.path.exists(lang):
    os.mkdir(lang)
phn_base = lang + '/phn/'
if not os.path.exists(phn_base):
    os.mkdir(phn_base)

for f in glob.glob(phn_base + '*'):
    os.remove(f)

# Split the dir into num_jobs file-lists.
# Pass each fileList to its own "phnrec -l fileList".
import subprocess
num_per_job = len(wavfiles)/num_jobs

dir = "../brno-phnrec/PhnRec"
config = "CZ" # todo: also HU and RU.
config = dir + "/PHN_" + config + "_SPDAT_LCRC_N1500"

for n in range(0, num_jobs):
    jobfilename = '%s%2.2d.txt' % (phn_base, n)
    idsfilename = '%s%2.2d.ids' % (phn_base, n)
    scrfilename = '%s%2.2d.scr' % (phn_base, n)
    with open(jobfilename, 'w') as f:
        with open(idsfilename, 'w') as g:
            for m in range(math.ceil(n*num_per_job), min(len(wavfiles), math.ceil((n+1)*num_per_job))):
                f.write('{}/{}\n'.format(dirWav, wavfiles[m]))
                g.write('{}\n'.format(ids[m]))
    # Spawn a new process in the background.
    # It writes foo.wav's transcription to foo.scr.
    print([dir+"/phnrec", "-c", config, "-l", jobfilename ])
    subprocess.Popen([dir+"/phnrec", "-c", config, "-l", jobfilename ])

# After all phnrec processes finish, run ./phnrec.rb to merge the transcriptions they made.
