#!/usr/bin/env python3

# Create a clean.txt (aka out.txt) with which to train a language model.
# For each unique word in clean.txt, estimate a pronunciation from a g2p table;
# store them in lexicon.txt.

import sys
import os
import re

USAGE='''USAGE: mkprondict.py in.txt in.dict out.txt out.dict words.txt phones.txt missing.txt

   Clean the words from in.txt: keep only the characters in in.dict, and eliminate >2 repeated chars.
   Write cleaned text into out.txt; write the prondict into out.dict.
   Write the word list and phone list into words.txt and phones.txt.
   Into missing.txt, report any characters in in.txt that were not in in.dict.'''

if len(sys.argv) != 8:
    print(USAGE)
    exit(0)

dummy, fileIntxt, fileIndict, fileOuttxt, fileOutdict, fileWords, filePhones, fileMissingchars = sys.argv

# Read fileIndict.
g2p = []
phoneset = {}
with open(fileIndict, 'r', encoding='utf-8') as f:
    for line in f:
        words = line.rstrip().split()
        if len(words) > 1:
            n = len(words[0]) - 1
            while n >= len(g2p):
                g2p.append({})
            g2p[n][words[0].upper()] = ' '.join(words[1:])
            for p in words[1:]:
                phoneset[p] = 1

# Read fileIntxt, convert words, and write fileOuttxt.
prondict = {}
missingchars = {}
with open(fileIntxt, 'r', encoding='utf-8') as f:
    with open(fileOuttxt, 'w', encoding='utf-8') as g:
        print('Cleaning text from %s into %s.' % (fileIntxt, fileOuttxt))
        for line in f:
            outwords = []
            for word in re.split('\W+', line.upper()):
                if word in prondict:
                    outwords.append(word)
                else:
                    rec = []
                    pron = ''
                    while word:
                        # Find the longest-matching char sequence.
                        for n in range(min(len(word), len(g2p)), -1, -1):
                            if n == 0:
                                # Character missing, so delete it from cleaned output.
                                missingchars[word[0]] = 1
                                word = word[1:]
                                break
                            elif word[0:n] in g2p[n-1]:
                                # Keep this to cleaned output only if it's not a triple-repetition.
                                if len(rec)<2 or word[0:n] != rec[-1] or rec[-1] != rec[-2]:
                                    rec.append(word[0:n])
                                    pron += ' ' + g2p[n-1][word[0:n]]
                                word = word[n:]
                                break
                    if rec:
                        rec = ''.join(rec)
                        prondict[rec] = pron
                        outwords.append(rec)
            if outwords:
                g.write(' '.join(outwords) + '\n')

# Write the dictionary.
with open(fileOutdict, 'w', encoding='utf-8') as f:
    print('Writing {}'.format(fileOutdict))
    for (k,v) in sorted(prondict.items()):
        f.write('%s %s\n' % (k,v))

# Write the list of missing chars.
with open(fileMissingchars, 'w', encoding='utf-8') as f:
    print('Writing {}'.format(fileMissingchars))
    for k in sorted(missingchars.keys()):
        f.write(k + '\n')

# Write the list of words.
with open(fileWords, 'w', encoding='utf-8') as f:
    print('Writing {}'.format(fileWords))
    for (n,w) in enumerate(sorted(prondict.keys())):
        f.write('{}\n'.format(w))

# Write the list of phones.
with open(filePhones, 'w') as f:
    print('Writing {}'.format(filePhones))
    for (n,p) in enumerate(sorted(phoneset.keys())):
        f.write('{}\n'.format(p))
