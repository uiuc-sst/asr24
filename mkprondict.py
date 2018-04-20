#!/usr/bin/env python3

# Inputs:
#   in.txt, raw IL prose; at most 60 MB (5M words, 500k lines) to keep this fast.
#   in.g2aspire.dict, a g2p for IL using Aspire's phonemes.
# Outputs:
#   out.txt, a cleaned-up in.txt: keep only the chars in in.g2aspire.dict, and eliminate >2 repeated chars.
#   out.dict, the words from out.txt, each with a pronunciation estimated from in.g2aspire.dict.
# Other outputs:
#   words.txt, out.txt's words.
#   phones.txt, the phones used by words.txt.
#   missing.txt, any characters in in.txt that were not in in.g2aspire.dict.

import sys
import os
import re

USAGE='''USAGE: mkprondict.py in.txt in.g2aspire.dict out.txt out.dict words.txt phones.txt missing.txt'''

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
            # Regex \d\s works better than \W in python 3.4.3
            for word in re.split('[\d\s]+', line.strip().upper()):
                if word in prondict:
                    # This word already appeared in fileIntxt.
                    outwords.append(word)
                elif word:
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
