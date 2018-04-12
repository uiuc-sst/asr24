#!/usr/bin/env python3

# Create a clean.txt (aka out.txt) with which to train a language model.
# For each unique word in clean.txt, estimate a pronunciation from a g2p table;
# store them in lexicon.txt.

import sys
import os
import re

USAGE='''USAGE: mkprondict.py in.txt in.dict out.txt out.dict words.txt phones.txt missing.txt

   Clean the words in in.txt: keep only the characters in in.dict, and eliminate >2 repeated chars.
   Write cleaned text into out.txt; write the prondict into out.dict.
   Write the word list and phone list into words.txt and phones.txt.
   Into missing.txt, report any characters in in.txt that were not in in.dict.'''

if len(sys.argv) != 8:
    print(USAGE)
    exit(0)

intxt = sys.argv[1]
indict = sys.argv[2]
outtxt = sys.argv[3]
outdict = sys.argv[4]
words = sys.argv[5]
phones = sys.argv[6]
missingchars = sys.argv[7]

# Read indict.
g2p = [{},{},{},{}];
phoneset = {}
with open(indict) as f:
    for line in f:
        f=line.rstrip().split()
        if len(f)>1:
            n = len(f[0])-1
            while n >= len(g2p):
                g2p.append({})
            g2p[n][f[0].upper()] = ' '.join(f[1:])
            for p in f[1:]:
                phoneset[p] = 1

# Read intxt, convert words, and write outtxt.
prondict = {}
missingchars = {}
with open(intxt) as f:
    with open(outtxt, 'w') as g:
        print('Cleaning text from %s into %s.' % (intxt, outtxt))
        for line in f:
            words = re.split('\W+', line)
            outwords = []
            for word in words:
                if word.upper() in prondict:
                    outwords.append(word.upper())
                else:
                    rec = []
                    pron = ''
                    test = word.upper()
                    while (len(test)>0):
                        # Find the longest-matching char sequence.
                        for n in range(min(len(test), len(g2p)), -1, -1):
                            if n==0:
                                # Character missing, so delete it from cleaned output.
                                missingchars[test[0]] = 1
                                test = test[1:]
                                break
                            elif test[0:n] in g2p[n-1]:
                                # Keep this to cleaned output only if it's not a triple-repetition.
                                if len(rec)<2 or test[0:n] != rec[-1] or rec[-1] != rec[-2]:
                                    rec.append(test[0:n])
                                    pron += ' '+g2p[n-1][test[0:n]]
                                test = test[n:]
                                break
                    if len(rec)>0:
                        prondict[''.join(rec)] = pron
                        outwords.append(''.join(rec))
            if len(outwords)>0:
                g.write(' '.join(outwords)+'\n')

# Eliminate the unwanted blank word.
if '' in prondict:
    del prondict['']
    
# Write the dictionary.
with open(outdict, 'w') as f:
    print('Writing {}'.format(outdict))
    for (k,v) in sorted(prondict.items()):
        if len(k) > 0:
            f.write('%s %s\n' % (k,v))

# Write the list of missing chars.
with open(missingchars, 'w') as f:
    print('Writing {}'.format(missingchars))
    for k in missingchars.keys():
        f.write(k+'\n')
        
# Write the list of words and the list of phones.
with open(words, 'w') as f:
    print('Writing {}'.format(words))
    for (n,w) in enumerate(sorted(prondict.keys())):
        f.write('{}\n'.format(w))
phones = {}
with open(phones, 'w') as f:
    for (n,p) in enumerate(sorted(phoneset.keys())):
        f.write('{}\n'.format(p))
