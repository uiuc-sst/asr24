# "queue.pl" uses qsub.  The options to it are
# options to qsub.  If you have GridEngine installed,
# change this to a queue you have access to.
# Otherwise, use "run.pl", which will run jobs locally.

export train_cmd="queue.pl"
export decode_cmd="queue.pl --mem 64G"
export mkgraph_cmd="queue.pl --mem 64G"
