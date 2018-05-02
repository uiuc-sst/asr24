#!/usr/bin/env python3

import sys
import io
import os.path
import csv
from collections import deque
from urllib import request

USAGE='''g2ipa2aspire.py g2ipa.txt aspire2ipa.txt phoiblefilename.csv
   Outputs g2aspire.txt, by compose(g2ipa, inverse(aspire2ipa.txt)).
   g2ipa.txt, aspire2ipa.txt, and g2aspire.txt are all text-format dictionaries.
   aspire2ipa must be one-to-one; any word after the second, on each line, is ignored.
   If g2ipa.txt includes IPA symbols that are not in aspire2ipa.txt, instead use
   the closest-matching symbols, determined by measuring feature vectors in phoiblefilename.csv,
   and finding minimum L0 feature vector distance.
'''

# For each grapheme in https://github.com/uiuc-sst/g2ps/blob/master/Arabic/Arabic_ref_orthography_dict.txt,
# for each of its corresponding phonemes,
#   (1) if the phoneme isn't in aspire2ipa.txt, use phoibletable.csv to find the aspire phoneme with the nearest list of distinctive features;
#   (2) replace the IPA symbol with the aspire symbol.
# Write the result to arabic2aspire.txt.
# The phoible table adds several entries to the one on the phoible GitHub.
# Some graphemes in arabic2aspire.txt have zero-length pronunciations.  That may upset mkprondict.py.

if len(sys.argv) < 4:
    print(USAGE)
    exit(0)
g2ipa_filename = sys.argv[1]
aspire2ipa_filename = sys.argv[2]
phoiblefilename = sys.argv[3]

# ipa2aspire maps str -> str, because it must be one-to-one.
ipa2aspire = {}
with open(aspire2ipa_filename) as f:
    for line in f:
        p = line.rstrip().split()
        if len(p) > 1:
            ipa2aspire[p[1]] = p[0]

# g2ipa maps str -> array(str), because it may be one-to-many.
g2ipa = {}
not_in_aspire = {}
with open(g2ipa_filename) as f:
    for line in f:
        p = deque(line.rstrip().split())
        if len(p) > 1:
            g = p.popleft()
            if not g in g2ipa:
                g2ipa[g] = []
            g2ipa[g].append(' '.join(p))
            # If any are missing from ipa2aspire, mark them.
            # (Use Set operations instead?)
            for ph in p:
                if ph not in ipa2aspire:
                    not_in_aspire[ph] = True

ipa2feats = {}
if len(not_in_aspire) > 0:
    # Read the ipa2feats table.
    with open(phoiblefilename) as csvfile:
        csvreader = csv.reader(csvfile)
        for row in csvreader:
            ipa2feats[row[0]] = row

# Find the aspire phoneme with minimum distance.
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

# Compose each entry in g2ipa with ipa2feats and ipa2aspire.
for (g, prons) in g2ipa.items():
    for pron in prons:
        p = pron.split()
        for n in range(0, len(p)):
            if p[n] == 'eps':
                # Arbitrary: add an entry mapping from 'eps' to zero-length output.
                # Is this the best way to deal with this?
                p[n] = ''
            else:
                if p[n] not in ipa2aspire:
                    p[n] = nearest_in_table(p[n], ipa2aspire, ipa2feats)
                p[n] = ipa2aspire[p[n]]
            print('{}\t{}'.format(g, ' '.join(p)))
