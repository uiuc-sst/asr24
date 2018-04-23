# asr24
24-hour ASR

Within 24 hours, train an ASR for a surprise language L, and get native transcriptions of recorded speech.

Use a pre-trained acoustic model, an L pronunciation dictionary, and an L language model.
This approach converts phones directly to L words, instead of using multiple cross-trained ASRs to make English words
from which phone strings are extracted, merged with [PTgen](https://github.com/uiuc-sst/PTgen), and reconstituted into L words (which turned out to be too noisy).

## How to install

#### Install Kaldi.
If you haven't already installed a version of Kaldi newer than 2016 Sep 30, `git clone https://github.com/kaldi-asr/kaldi` and build it, following the instructions in its INSTALL files:
```
    cd kaldi/tools; make -j $(nproc)
    cd ../src; ./configure --shared && make depend -j $(nproc) && make -j $(nproc)
```

#### Get this repo's code.
It goes into a directory `asr24`, a sister of the usual `s5` directory.
```
    cd kaldi/egs/aspire
    git clone https://github.com/uiuc-sst/asr24.git
    cd asr24
```

#### Set up Krisztián Varga's [extension](https://chrisearch.wordpress.com/2017/03/11/speech-recognition-using-kaldi-extending-and-using-the-aspire-model/) of [ASpIRE](http://kaldi-asr.org/models.html).
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

#### Get the speech recordings.
On ifp-serv-03.ifp.illinois.edu, get LDC speech:
```
    cd /ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Russian/LDC2016E111/RUS_20160930
    cd /ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Tamil/TAM_EVAL_20170601/TAM_EVAL_20170601
    cd /ws/ifp-serv-03_1/workspace/fletcher/fletcher1/speech_data1/Uzbek/LDC2016E66/UZB_20160711

    mkdir /tmp/8k
    for f in */AUDIO/*.flac; do sox "$f" -r 8000 -c 1 /tmp/8k/$(basename ${f%.*}.wav); done
    tar cf /workspace/ifp-53_1-data/eval/8k.tar -C /tmp 8k
    rm -rf /tmp/8k
```
Then, on the campus cluster:
```
    cd /projects/beckman/jhasegaw/kaldi/egs/aspire/asr24
    wget -qO- http://www.ifp.illinois.edu/~camilleg/e/8k.tar | tar xf
    mv 8k $L-8khz
```

#### Transcribe the speech.
- `./mkprondict.py $L/train_all/text g2aspire-$L.txt $L/lang/clean.txt $L/local/dict/lexicon.txt $L/local/dict/words.txt /tmp/phones.txt /tmp/letters-culled-by-cleaning.txt` makes files needed by the subsequent steps (but the /tmp files aren't used).  
  (`/tmp/phones.txt` is a subset of `$L/local/dict/nonsilence_phones.txt`, which is the standard Aspire version.)
- `./newlangdir_train_lms.sh $L` makes a language model for L.
- `./newlangdir_make_graphs.sh $L`, probably on ifp-53, makes L.fst, G.fst, and then an L-customized HCLG.fst.

On the campus cluster:
- `./mkscp.py $L-8khz 20 $L` splits the transcription tasks into jobs shorter than the 30-minute maximum of the campus cluster's secondary queue.
Its input is `$L-8khz`, a dir of 8 kHz speech files, each named something like TAM_EVAL_072_008.wav.
`20` is the number of jobs.
Its output is shell script for each job, `$L/cmd/$L_42.sh`.
- `./$L-submit.sh` launches all these jobs.
