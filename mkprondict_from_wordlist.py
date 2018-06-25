#!/usr/bin/env python3

import sys
import os
import re

USAGE='''USAGE: mkprondict_from_wordlist.py <newlangdir>.  Make prondict from input wordlist, which is assumed to already match the language model.'''

if len(sys.argv) != 2:
    print(USAGE)
    exit(1)
L = sys.argv[1]

# Inputs.
fileInwords = L + "/local/dict/words.txt"   # Input wordlist, one word per line
fileIndict = L + "-g2aspire.txt"    # A g2p for IL using Aspire's phonemes.

# Outputs.
fileOutdict = L + "/local/dict/lexicon.txt" # fileOuttxt's words, each with a pronunciation estimated from fileIndict.

# Extra outputs.
filePhones = "/tmp/phones.txt"          # fileOuttxt's phones, a subset of L/local/dict/nonsilence_phones.txt, which is the standard Aspire version.

# Make dirs of output files.
for filename in [fileOutdict, filePhones]:
    os.makedirs(os.path.dirname(filename), exist_ok=True)

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

# Check that the g2p's phones are all Aspire phones.
phonesetAspire = {}
# These are $dict_src/silence_phones.txt.
phonesetAspire['sil'] = 1
phonesetAspire['laughter'] = 1
phonesetAspire['noise'] = 1
phonesetAspire['oov'] = 1
with open('nonsilence_phones.txt', 'r', encoding='utf-8') as f:
    for line in f:
        phonesetAspire[line.strip()] = 1
phonesBogus = set(phoneset.keys()) - set(phonesetAspire.keys())
if phonesBogus:
    print('Invalid phones in ' + fileIndict + ': ' + str(phonesBogus))
    exit(1)

# Read fileInwords.  Convert words.
prondict = {}
with open(fileInwords, 'r', encoding='utf-8') as f:
    print('Making prondict from %s.' % fileInwords)
    for line in f:
        # Assume one word per line.  Strip off newline, and uppercase it.
        word = line.rstrip().upper()
        if not word:
            continue
        if word in prondict:
            print('Invalid duplicate word ' + word + ' in cleaned wordlist ' + fileInwords)
            exit(1)
        rec = []
        pron = ''
        while word:
            # Find the longest-matching char sequence.
            for n in range(min(len(word), len(g2p)), -1, -1):
                if n == 0:
                    print('Invalid char "' + word[0] + '" in cleaned wordlist ' + fileInwords)
                    exit(1)
                elif word[0:n] in g2p[n-1]:
                    rec.append(word[0:n])
                    pron += ' ' + g2p[n-1][word[0:n]]
                    word = word[n:]
                    break
        if rec:
            prondict[''.join(rec)] = pron

# Write the dictionary.
with open(fileOutdict, 'w', encoding='utf-8') as f:
    print('Writing {}'.format(fileOutdict))
    for (k,v) in sorted(prondict.items()):
        f.write('%s %s\n' % (k,v))

# Write the list of phones.
with open(filePhones, 'w') as f:
    print('Writing {}'.format(filePhones))
    for (n,p) in enumerate(sorted(phoneset.keys())):
        f.write('{}\n'.format(p))
