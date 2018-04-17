export KALDI_ROOT=$PWD/../../..
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "Missing $KALDI_ROOT/tools/config/common_path.sh. Aborting." && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
[ -f $KALDI_ROOT/tools/env.sh ] && . $KALDI_ROOT/tools/env.sh	# For SRILM.
export PATH=$KALDI_ROOT/tools/sctk/bin:$PATH
export LC_ALL=C
