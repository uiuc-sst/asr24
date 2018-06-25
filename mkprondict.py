#!/usr/bin/env python3

import sys
import os
import re

USAGE='''USAGE: mkprondict.py <newlangdir>'''

if len(sys.argv) != 2:
    print(USAGE)
    exit(1)
L = sys.argv[1]

# Inputs.
fileIntxt = L + "/train_all/text"   # Raw IL prose; at most 60 MB (5M words, 500k lines) to keep this fast.
fileIndict = L + "-g2aspire.txt"    # A g2p for IL using Aspire's phonemes.

# Outputs.
fileOuttxt = L + "/lang/clean.txt"  # Cleaned-up fileIntxt.  keep only the chars in in.g2aspire.dict, and eliminate >2 repeated chars.
fileOutdict = L + "/local/dict/lexicon.txt" # fileOuttxt's words, each with a pronunciation estimated from fileIndict.

# Extra outputs.
fileWords = L + "/local/dict/words.txt" # fileOuttxt's words.
filePhones = "/tmp/phones.txt"          # fileOuttxt's phones, a subset of L/local/dict/nonsilence_phones.txt, which is the standard Aspire version.
fileMissingchars = "/tmp/letters-culled-by-cleaning.txt"    # Any characters in fileIntxt that were not in fileIndict.

# Make dirs of output files.
for filename in [fileOuttxt, fileOutdict, fileMissingchars, fileWords, filePhones]:
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
                if not word:
                    continue
                if word in prondict:
                    # This word already appeared in fileIntxt.
                    outwords.append(word)
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
