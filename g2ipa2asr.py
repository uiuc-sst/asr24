#!/usr/bin/env python3

import sys, io, csv
from collections import deque

USAGE='''g2ipa2asr.py g2ipa.txt asr2ipa.txt phoibletable.csv > g2asr.txt
   Composes g2ipa with the inverse of asr2ipa.txt.
   The inputs g2ipa.txt, asr2ipa.txt, and g2asr.txt are all text-format dictionaries.
   asr2ipa.txt: each line is an ASR phone, whitespace, and the corresponding IPA phone.
   g2ipa.txt: each line is a grapheme followed by IPA symbols, whitespace-delimited;
       typically something like Arabic_ref_orthography_dict.txt;
       if it includes IPA symbols that are not in asr2ipa.txt, we instead use
       the closest-matching symbols, determined by measuring feature vectors in phoibletable.csv
       and finding the minimum L0 feature vector distance.
   The output g2asr.txt has the same format as g2asr.txt, but with ASR phones instead of IPA phones.
   The output may include zero-length pronunciations.
'''

if len(sys.argv) < 4:
    print(USAGE)
    exit(0)
dummy, g2ipa_filename, asr2ipa_filename, phoiblefilename = sys.argv

# Map str -> str, because it must be one-to-one.
ipa2asr = {}
with open(asr2ipa_filename) as f:
    for line in f:
        p = line.rstrip().split()
        if len(p) > 1:
            ipa2asr[p[1]] = p[0]

# Map str -> array(str), because it may be one-to-many.
g2ipa = {}
not_in_asr = {}
with open(g2ipa_filename) as f:
    for line in f:
        p = deque(line.rstrip().split())
        if len(p) > 1:
            g = p.popleft()
            if not g in g2ipa:
                g2ipa[g] = []
            g2ipa[g].append(' '.join(p))
            # If any are missing from ipa2asr, mark them.
            # (Use Set operations instead?)
            for ph in p:
                if ph not in ipa2asr:
                    not_in_asr[ph] = True

ipa2feats = {}
if len(not_in_asr) > 0:
    # Read the ipa2feats table.
    with open(phoiblefilename) as csvfile:
        csvreader = csv.reader(csvfile)
        for row in csvreader:
            ipa2feats[row[0]] = row

# Find the asr phoneme with minimum distance.
def nearest_in_table(phone, table, ipa2feats):
    phfeats = ipa2feats[phone]
    mincost = len(phfeats)+1
    bestoutput = '<unk>'
    for testph in table.keys():
        testfeats = ipa2feats[testph]
        # Count how many features differ between testfeats and phfeats.
        cost = len([n for n in range(0, len(phfeats)) if testfeats[n] != phfeats[n]])
        # Keep the one with lowest cost.
        if cost < mincost:
            mincost = cost
            bestoutput = testph
    return(bestoutput)

# Compose each entry in g2ipa with ipa2feats and ipa2asr.
for (g, prons) in g2ipa.items():
    for pron in prons:
        p = pron.split()
        for n in range(0, len(p)):
            if p[n] == 'eps':
                # Arbitrary: add an entry mapping from 'eps' to zero-length output.
                # Is this the best way to deal with this?
                p[n] = ''
            else:
                if p[n] not in ipa2asr:
                    p[n] = nearest_in_table(p[n], ipa2asr, ipa2feats)
                p[n] = ipa2asr[p[n]]
        print('{}\t{}'.format(g, ' '.join(p)))
