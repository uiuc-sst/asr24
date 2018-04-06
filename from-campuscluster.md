## Only in /scratch/users/cog/kaldi/egs/aspire/s5:
```
job.sh
tam-Saturday-init.sh    // builds wav.scp and utts.txt
tam-Saturday.sh         // after tam-Saturday-init.sh
tam-all.out             // scrips up to TAM_EVAL_005_007
utts.txt                // built by tam-Saturday-init.sh
```
``qsub -q secondary -d `pwd` -l walltime=00:00:15,nodes=1 tam-Saturday.sh``

## Only in /scratch/users/jhasegaw/kaldi/egs/aspire/s5:
```
local/newlangdir_train_lms.sh
dutch8k/
dutch_transcriptions.txt
logfiles/
mystery2018feb27.wav
newlangdir_make_graphs.sh
russian/
russian_00.sh.e7047772
russian_transcripts.txt
tamil/
tamil_eval_transcripts.txt
tamil_ni_transcripts.txt
utt2spk
```
``qsub -d `pwd` -l walltime=00:90:00,nodes=2 job.sh``

## Different:
```
cmd.sh
exp/tdnn_7b_chain_online/conf/ivector_extractor.conf
exp/tdnn_7b_chain_online/conf/online.conf
utils/validate_dict_dir.pl
wav.scp: "TAM_EVAL_002_001 /scratch/users/cog/tam.8khz/TAM_EVAL_002_001.wav" or "dutch_140903_358463-19 dutch8k/dutch_140903_358463-19.wav"
```
