#!/usr/bin/env python3

# Create a clean.txt (aka out.txt) with which to train a language model.
# For each unique word in clean.txt, estimate a pronunciation from a g2p table;
# store them in lexicon.txt.

import sys
import os
import re

USAGE='''USAGE: mkprondict.py in.txt out.txt in.dict out.dict missing.txt words.txt phones.txt

   Clean the words in in.txt: keep only the characters in in.dict, and eliminate >2 repeated chars.
   Write cleaned text to out.txt; write the prondict to out.dict.
   Write enumerated lists of words and phones in words.txt and phones.txt.
   Into missing.txt, report any characters in in.txt that were not in in.dict.'''

if len(sys.argv) < 8:
    print(USAGE)
    exit(0)

intxtfile=sys.argv[1]
outtxtfile = sys.argv[2]
indictfile = sys.argv[3]
outdictfile = sys.argv[4]
missingcharsfile = sys.argv[5]
wordsfile = sys.argv[6]
phonesfile = sys.argv[7]

# Read indictfile
g2p = [{},{},{},{}];
phoneset = {}
with open(indictfile) as f:
    for line in f:
        f=line.rstrip().split()
        if len(f)>1:
            n = len(f[0])-1
            while n >= len(g2p):
                g2p.append({})
            g2p[n][f[0].upper()] = ' '.join(f[1:])
            for p in f[1:]:
                phoneset[p] = 1


# Read intxtfile, convert words, and write outtxtfile
prondict = {}
missingchars = {}
with open(intxtfile) as f:
    with open(outtxtfile,'w') as g:
        print('Converting text from %s to %s' % (intxtfile,outtxtfile))
        for line in f:
            words = re.split('\W+',line)
            outwords = []
            for word in words:
                if word.upper() in prondict:
                    outwords.append(word.upper())
                else:
                    rec = []
                    pron = ''
                    test = word.upper()
                    while(len(test)>0):
                        # Look for the longest-matching char sequence
                        for n in range(min(len(test),len(g2p)),-1,-1):
                            if n==0:
                                # character missing; delete it from cleaned outupt
                                missingchars[test[0]] = 1
                                test = test[1:]
                                break
                            elif test[0:n] in g2p[n-1]:
                                # keep this to cleaned output only if it's not a triple-repetition
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

# Eliminate the unwanted blank word
#if '' in prondict:
#    del prondict['']
    
# Write the dictionary
with open(outdictfile,'w') as f:
    print('Writing {}'.format(outdictfile))
    for (k,v) in sorted(prondict.items()):
        if len(k) > 0:
            f.write('%s %s\n' % (k,v))

# Write the list of missing chars
with open(missingcharsfile,'w') as f:
    print('Writing {}'.format(missingcharsfile))
    for k in missingchars.keys():
        f.write(k+'\n')
        
# Write the list of words and the list of phones
with open(wordsfile,'w') as f:
    print('Writing {}'.format(wordsfile))
    for (n,w) in enumerate(sorted(prondict.keys())):
        f.write('{}\n'.format(w))
phones = {}
with open(phonesfile,'w') as f:
    for (n,p) in enumerate(sorted(phoneset.keys())):
        f.write('{}\n'.format(p))
