```css
DIV.repository-content {
display: table
}
DIV.js-repo-meta-container {
display: table-caption
}
DIV.readme {
display: table-header-group
}
```
Well within 24 hours, transcribe 40 hours of recorded speech in a surprise language.

Build an ASR for a surprise language L from a pre-trained acoustic model, an L pronunciation dictionary, and an L language model.
This approach converts phones directly to L words.  This is less noisy than using multiple cross-trained ASRs to make English words
from which phone strings are extracted, merged by [PTgen](https://github.com/uiuc-sst/PTgen), and reconstituted into L words.

<!-- To refresh this TOC, 
Just once:
  `wget https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc`
  `chmod a+x gh-md-toc`
When README.md updates:
  `./gh-md-toc --insert README.md`
-->
<!--ts-->
   * [Install software:](#install-software)
         * [Kaldi](#kaldi)
         * [brno-phnrec](#brno-phnrec)
         * [This repo](#this-repo)
         * [Extension of ASpIRE](#extension-of-aspire)
         * [CVTE Mandarin](#cvte-mandarin)
   * [For each language L, build an ASR:](#for-each-language-l-build-an-asr)
         * [Get raw text.](#get-raw-text)
         * [Get a G2P.](#get-a-g2p)
         * [Build an ASR.](#build-an-asr)
   * [Transcribe speech:](#transcribe-speech)
         * [Get recordings.](#get-recordings)
         * [Typical results.](#typical-results)

<!-- Added by: camilleg, at: 2018-05-25T15:30-0500 -->

<!--te-->

# Install software:

### Kaldi
If you don't already have a version of Kaldi newer than 2016 Sep 30,
get and build it following the instructions in its INSTALL files.
```
    git clone https://github.com/kaldi-asr/kaldi
    cd kaldi/tools; make -j $(nproc)
    cd ../src; ./configure --shared && make depend -j $(nproc) && make -j $(nproc)
```

### brno-phnrec
Put Brno U. of Technology's phoneme recognizer next to the usual s5 directory.
```
    sudo apt-get install libopenblas-dev libopenblas-base
    cd kaldi/egs/aspire
    git clone https://github.com/uiuc-sst/brno-phnrec.git
    cd brno-phnrec/PhnRec
    make
```

### This repo
Put this next to the usual `s5` directory.  
(The package nodejs is for `./sampa2ipa.js`.)
```
    sudo apt-get install nodejs
    cd kaldi/egs/aspire
    git clone https://github.com/uiuc-sst/asr24.git
    cd asr24
```

### Extension of ASpIRE
- Get the [ASpIRE chain model](http://kaldi-asr.org/models.html),
[extended](https://chrisearch.wordpress.com/2017/03/11/speech-recognition-using-kaldi-extending-and-using-the-aspire-model/) by Krisztián Varga.
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
In exp/tdnn_7b_chain_online this builds the files `phones.txt`, `tree`, `final.mdl`, `conf/`, etc.  
This builds the subdirectories `data` and `exp`.  Its last command `mkgraph.sh` can take 45 minutes (30 for CTVE Mandarin) and use a lot of memory because it calls `fstdeterminizestar` on a large language model, as Dan Povey [explains](https://groups.google.com/forum/#!topic/kaldi-help/3C6ypvqLpCw).

- Verify that it can transcribe English, in mono 16-bit 8 kHz .wav format.
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

### CVTE Mandarin
- Get the [Mandarin chain model](http://kaldi-asr.org/models.html) (3.4 GB, about 10 minutes).
This makes a subdir cvte/s5, containing a words.txt, HCLG.fst, and final.mdl.
```
    wget -qO- http://kaldi-asr.org/models/0002_cvte_chain_model.tar.gz | tar xz
    steps/online/nnet3/prepare_online_decoding.sh \
      --mfcc-config conf/mfcc_hires.conf \
      data/lang_chain exp/nnet3/extractor \
      exp/chain/tdnn_7b cvte/s5/exp/chain/tdnn
    utils/mkgraph.sh --self-loop-scale 1.0 data/lang_pp_test \
      cvte/s5/exp/chain/tdnn cvte/s5/exp/chain/tdnn/graph_pp
```

# For each language L, build an ASR:

### Get raw text.
- Into `$L/train_all/text` put word strings in L (scraped from wherever), roughly 10 words per line, at most 500k lines.  These may be quite noisy, because they'll be cleaned up.

### Get a G2P.
- Get a G2P `g2aspire-$L.txt`, a few hundred lines each containing grapheme(s), whitespace, and space-delimited Aspire-style phones.  
If that file has CR line terminators, convert them to standard ones in vim with the command `%s/^M/\r/g`, typing `^V` before the `^M`.  
If that file begins with a BOM, remove it: `vi -b g2aspire-$L.txt`, and just `x` that character away.  

- If you need to build it, `./g2ipa2asr.py $L_wikipedia_symboltable.txt aspire2ipa.txt phoibletable.csv > g2aspire-$L.txt`.

### Build an ASR.
On ifp-53:  
- `./run.sh $L` makes an L-customized HCLG.fst.  
*(To instead run individual stages of run.sh:*  
- `./mkprondict.py $L` reads `$L/train_all/text` and makes files needed by the subsequent stages, including `$L/local/dict/lexicon.txt` and `$L/local/dict/words.txt`.  
- `./newlangdir_train_lms.sh $L` makes a word-trigram language model for L, `$L/local/lm/3gram-mincount/`.
- `./newlangdir_make_graphs.sh $L` makes L.fst, G.fst, and then `$L/graph/HCLG.fst`.  
*)*  

- If the host that will do transcribing is the campus cluster, copy some files to it.  
  On ifp-53, `cp -p $L/lang/phones.txt $L/graph/words.txt $L/graph/HCLG.fst ~camilleg/l/eval/`.  
  On campus cluster, `cd $L/lang; wget http://www.ifp.illinois.edu/~camilleg/e/phones.txt; cd ../graph; wget http://www.ifp.illinois.edu/~camilleg/e/words.txt; wget http://www.ifp.illinois.edu/~camilleg/e/HCLG.fst`.  
- On each host that will do transcribing, `./newlangdir_make_confs.sh $L` makes some config files.

# Transcribe speech:
### Get recordings.
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
On ifp-53,
```
    mkdir ~/kaldi/egs/aspire/asr24/$L-8khz
    cd myTmpSphDir
    tar xf /tmp/foo.tar
    for f in *.sph; do ~/kaldi/tools/sph2pipe_v2.5/sph2pipe -p -f rif "$f" /tmp/a.wav; \
        sox /tmp/a.wav -r 8000 -c 1 ~/kaldi/egs/aspire/asr24/$L-8khz/$(basename ${f%.*}.wav); done
```
On the host that will run the transcribing, e.g. campus cluster or ifp-53:
```
    cd kaldi/egs/aspire/asr24
    wget -qO- http://www.ifp.illinois.edu/~camilleg/e/8k.tar | tar xf -
    mv 8k $L-8khz
```

- `./mkscp.py $L-8khz $(nproc) $L` splits the ASR tasks into one job per CPU core.  
(On campus cluster, replace `$(nproc)` with a number large enough so each job completes within the secondary queue's 10-minute limit.  For Tamil, try 30.)  
It reads `$L-8khz`, the dir of 8 kHz speech files.  
It makes `$L-submit.sh`.  
- `./$L-submit.sh` launches these jobs in parallel.
- After those jobs complete, collect the transcriptions with  
`grep -h -e '^TAM_EVAL' $L/lat/*.log | sort > $L-scrips.txt` (or ...`^RUS_`, `^BABEL_`, etc.).
- To sftp transcriptions to Jon May as `elisa.tam-eng.eval-asr-uiuc.y3r1.v8.xml.gz`,
with timestamp June 11 and version 8,  
`grep -h -e '^TAM_EVAL' tamil/lat/*.log | sort | sed -e 's/ /\t/' | ./hyp2jonmay.rb /tmp/jon-tam tam 20180611 8`  
(If UTF-8 errors occur, simplify letters by appending to the sed command args such as `-e 's/Ñ/N/g'`.)
- Collect each .wav file's n best transcriptions with  
`cat $L/lat/*.ascii | sort > $L-nbest.txt`.

### Typical results.

RUS_20160930 was transcribed in 67 minutes, 13 MB/min, **12x** faster than real time.

A 3.1 GB subset of Assam LDC2016E02 was transcribed in 440 minutes, 7 MB/min, **6.5x** real time.  (This may have been slower because it exhausted ifp-53's memory.)

Arabic/NEMLAR_speech/NMBCN7AR, 2.2 GB (40 hours), was [transcribed](./arabic-scrips.txt) in 147 minutes, 14 MB/min, **16x** real time.  (This may have been faster because it was a few long (half-hour) files instead of many brief ones.)

TAM_EVAL_20170601 was [transcribed](./tamil-scrips-ifp53.txt) in 45 minutes, 21 MB/min, **19x** real time.  
On campus cluster, it was [transcribed](./tamil-scrips-ccluster.txt) in 45 minutes,
but 26 of the 150 7-utterance jobs were aborted at 10 cpu-minutes
(because some utterances are longer; mkscp.py should split jobs by .wav duration instead).
Even accounting for that, the transcriptions differ slightly from ifp-53's.

Generating lattices `$L/lat/*` took 1.04x longer for Russian, 0.93x longer(!) for Arabic, 1.7x longer for Tamil.
