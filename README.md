# asr24
24-hour ASR

Within 24 hours, train an ASR for a surprise language L, and get native transcriptions of recorded speech.

Use a pre-trained acoustic model, an L pronunciation dictionary, and an L language model.
This approach converts phones directly to L words, instead of using multiple cross-trained ASRs to make English words
from which phone strings are extracted, merged with [PTgen](https://github.com/uiuc-sst/PTgen), and reconstituted into L words (which turned out to be too noisy).

<!-- To refresh this TOC, 
Just once:
  `wget https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc`
  `chmod a+x gh-md-toc`
When README.md updates:
  `./gh-md-toc --insert README.md`
-->
<!--ts-->
   * [asr24](#asr24)
   * [Install software.](#install-software)
         * [Install Kaldi.](#install-kaldi)
         * [Get this repo's code.](#get-this-repos-code)
         * [Set up Krisztián Varga's <a href="https://chrisearch.wordpress.com/2017/03/11/speech-recognition-using-kaldi-extending-and-using-the-aspire-model/" rel="nofollow">extension</a> of <a href="http://kaldi-asr.org/models.html" rel="nofollow">ASpIRE</a>.](#set-up-krisztián-vargas-extension-of-aspire)
   * [For each language L, build an ASR.](#for-each-language-l-build-an-asr)
         * [Get raw text, G2P, etc.](#get-raw-text-g2p-etc)
         * [Build the ASR.](#build-the-asr)
   * [Transcribe speech.](#transcribe-speech)
         * [Get speech recordings.](#get-speech-recordings)
         * [On the campus cluster:](#on-the-campus-cluster)
         * [On ifp-53:](#on-ifp-53)

<!-- Added by: camilleg, at: 2018-04-25T16:05-0500 -->

<!--te-->

# Install software.

### Install Kaldi.
If you haven't already installed a version of Kaldi newer than 2016 Sep 30, `git clone https://github.com/kaldi-asr/kaldi` and build it, following the instructions in its INSTALL files:
```
    cd kaldi/tools; make -j $(nproc)
    cd ../src; ./configure --shared && make depend -j $(nproc) && make -j $(nproc)
```

### Get this repo's code.
It goes into a directory `asr24`, a sister of the usual `s5` directory.
```
    cd kaldi/egs/aspire
    git clone https://github.com/uiuc-sst/asr24.git
    cd asr24
```

### Set up Krisztián Varga's [extension](https://chrisearch.wordpress.com/2017/03/11/speech-recognition-using-kaldi-extending-and-using-the-aspire-model/) of [ASpIRE](http://kaldi-asr.org/models.html).
- Get the [ASpIRE chain model](http://kaldi-asr.org/models.html):
```
    cd kaldi/egs/aspire/asr24
    wget -qO- http://dl.kaldi-asr.org/models/0001_aspire_chain_model.tar.gz | tar xz
    steps/online/nnet3/prepare_online_decoding.sh \
      --mfcc-config conf/mfcc_hires.conf \
      data/lang_chain exp/nnet3/extractor \
      exp/chain/tdnn_7b exp/tdnn_7b_chain_online
    utils/mkgraph.sh --self-loop-scale 1.0 data/lang_pp_test \
      exp/tdnn_7b_chain_online exp/tdnn_7b_chain_online/graph_pp
```
This builds the subdirectories `data` and `exp`.  Its last command `mkgraph.sh` can take 45 minutes and use a lot of memory because it calls `fstdeterminizestar` on a large language model, as Dan Povey [explains](https://groups.google.com/forum/#!topic/kaldi-help/3C6ypvqLpCw).

- Verify that it can transcribe a recording of English speech, in mono 16-bit 8 kHz .wav format.
Either use the provided 8khz.wav,
or `sox MySpeech.wav -r 8000 8khz.wav`,
or `ffmpeg -i MySpeech.wav -acodec pcm_s16le -ac 1 -ar 8000 8khz.wav`.

(The scripts `cmd.sh` and `path.sh` say where to find `kaldi/src/online2bin/online2-wav-nnet3-latgen-faster`.)
```
    . cmd.sh && . path.sh
    online2-wav-nnet3-latgen-faster \
      --online=false  --do-endpointing=false \
      --frame-subsampling-factor=3 \
      --config=exp/tdnn_7b_chain_online/conf/online.conf \
      --max-active=7000 \
      --beam=15.0  --lattice-beam=6.0  --acoustic-scale=1.0 \
      --word-symbol-table=exp/tdnn_7b_chain_online/graph_pp/words.txt \
      exp/tdnn_7b_chain_online/final.mdl \
      exp/tdnn_7b_chain_online/graph_pp/HCLG.fst \
      'ark:echo utterance-id1 utterance-id1|' \
      'scp:echo utterance-id1 8khz.wav|' \
      'ark:/dev/null'
```

# For each language L, build an ASR.

### Get raw text, G2P, etc.

- Into `$L/train_all/text` put word strings in L (scraped from wherever), roughly 10 words per line, at most 500k lines.  These can be quite noisy, because they'll be cleaned up.
- Get a G2P `g2aspire-$L.txt`, a few hundred lines each containing grapheme(s), whitespace, and space-delimited Aspire-style phones.  
If that file has CR line terminators, convert them to standard ones in vim with the command `%s/^M/\r/g`, typing `^V` before the `^M`.  
If that file begins with a BOM, remove it: `vi -b g2aspire-$L.txt`, and just `x` that character away.  

- If you need to build the G2P, `./g2ipa2asr.py $L_wikipedia_symboltable.txt aspire2ipa.txt phoibletable.csv > g2aspire-$L.txt`.

### Build the ASR.
- `./mkprondict.py $L/train_all/text $L-g2aspire.txt $L/lang/clean.txt $L/local/dict/lexicon.txt $L/local/dict/words.txt /tmp/phones.txt /tmp/letters-culled-by-cleaning.txt` makes files needed by the subsequent steps (but the /tmp files aren't used).  
  (`/tmp/phones.txt` is a subset of `$L/local/dict/nonsilence_phones.txt`, which is the standard Aspire version.)
- `./newlangdir_train_lms.sh $L` makes a language model for L, `$L/local/lm/3gram-mincount/lm_unpruned.gz`.
- On ifp-53, `./newlangdir_make_graphs.sh $L` makes L.fst, G.fst, and then an L-customized HCLG.fst.
- On ifp-53, `scp $L/graph/HCLG.fst cog@golubh1.campuscluster.illinois.edu:/projects/beckman/jhasegaw/kaldi/egs/aspire/asr24/$L/graph/HCLG.fst`
- If the host that will do transcribing is the campus cluster, copy some files to it.
  On ifp-53, `cp -p $L/lang/phones.txt $L/graph/words.txt ~camilleg/l/eval/`.
  On campus cluster, `cd $L/lang; wget http://www.ifp.illinois.edu/~camilleg/e/phones.txt; cd ../graph; wget http://www.ifp.illinois.edu/~camilleg/e/words.txt`.
- On each host that will do transcribing, `./newlangdir_make_confs.sh $L` makes some config files.

# Transcribe speech.
### Get speech recordings.
On ifp-serv-03.ifp.illinois.edu, get LDC speech and convert it to a flat dir of 8 kHz .wav files:
```
    cd /ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Russian/LDC2016E111/RUS_20160930
    cd /ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Tamil/TAM_EVAL_20170601/TAM_EVAL_20170601
    cd /ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Uzbek/LDC2016E66/UZB_20160711

    mkdir /tmp/8k
    for f in */AUDIO/*.flac; do sox "$f" -r 8000 -c 1 /tmp/8k/$(basename ${f%.*}.wav); done
    tar cf /workspace/ifp-53_1-data/eval/8k.tar -C /tmp 8k
    rm -rf /tmp/8k
```
For BABEL .sph files:
```
    cd /ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Assamese/LDC2016E02/conversational/training/audio
    tar cf /tmp/foo.tar BABEL*.sph
    scp /tmp/foo.tar ifp-53:/tmp
```
Then on ifp-53,
```
    mkdir ~/kaldi/egs/aspire/asr24/$L-8khz
    cd myTmpSphDir
    tar xf /tmp/foo.tar
    for f in *.sph; do ~/kaldi/tools/sph2pipe_v2.5/sph2pipe -p -f rif "$f" /tmp/a.wav; \
        sox /tmp/a.wav -r 8000 -c 1 ~/kaldi/egs/aspire/asr24/$L-8khz/$(basename ${f%.*}.wav); done
```
Choose a host to run the transcribing, e.g. campus cluster or ifp-53.  On that host:
```
    cd kaldi/egs/aspire/asr24
    wget -qO- http://www.ifp.illinois.edu/~camilleg/e/8k.tar | tar xf -
    mv 8k $L-8khz
```

### On campus cluster:
- `./mkscp.py $L-8khz 20 $L` splits the transcription tasks into jobs shorter than the 10-minute maximum of the campus cluster's secondary queue.
Its reads `$L-8khz`, a dir of 8 kHz speech files.
`20` is the number of jobs, found empirically.
It makes $L-submit.sh.
- `./$L-submit.sh` launches these jobs in parallel.
- `cat $L*.sh.e* | grep -e ^TAM_EVAL | sort`, ...`^RUS_`, `^BABEL_`, etc., extracts the transcriptions.

TAM_EVAL_20170601 was [transcribed](./tamil-scrips-ccluster.txt) in 45 minutes,
but 26 of the 150 7-utterance jobs were aborted at 10 cpu-minutes
(because some utterances are longer; mkscp.py should split jobs by .wav duration instead).
Even accounting for that, the transcriptions differ slightly from ifp-53's.

### On ifp-53:
- `./mkscp.py $L-8khz $(nproc) $L` splits the tasks into one job per CPU core.
- `./$L-submit.sh 2> $L.out` launches these jobs in parallel.
- `cat $L.out | grep -e ^TAM_EVAL | sort` extracts the transcriptions.  (This isn't [Useless Use Of Cat](http://porkmail.org/era/unix/award.html) because it stops grep from thinking that `$L.out` is binary rather than text and suppressing the actual output.)

TAM_EVAL_20170601 was [transcribed](./tamil-scrips-ifp53.txt) in 45 minutes, 21 MB/min, **19x** faster than real time.  
RUS_20160930 was transcribed in 67 minutes, 13 MB/min, **12x** real time.  
A 3.1 GB subset of Assam LDC2016E02 was transcribed in 440 minutes, 7 MB/min, **6.5x** real time.  (This may have been slower because it exhausted ifp-53's memory.)  
Arabic/NEMLAR_speech/NMBCN7AR, 2.2 GB (40 hours), was [transcribed](./arabic-scrips.txt) in 147 minutes, 14 MB/min, **16x** real time.  (This may have been faster because it was a few long (half-hour) files instead of many brief ones.)
