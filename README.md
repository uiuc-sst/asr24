# asr24
24-hour ASR

Within 24 hours, train an ASR for a surprise incident language (IL), and get native transcriptions of recorded speech.

Use Kaldi Aspire's pre-trained acoustic models, an IL dictionary, and an IL language model.
This approach converts phones directly to NI words, instead of using multiple cross-trained ASRs to make English words
from which phones are extracted and then reconstituted into IL words;  that has turned out to be too noisy.
