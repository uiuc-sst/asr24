#!/usr/bin/env python3

import sys, os, re

USAGE='''USAGE: mkprondict.py <newlangdir>'''
if len(sys.argv) != 2:
    print(USAGE)
    exit(1)
L = sys.argv[1]

# Inputs.
fileIntxt = L + "/train_all/text"   # Raw IL prose; at most 60 MB (5M words, 500k lines) to keep this fast.
fileIndict = L + "-g2aspire.txt"    # A g2p for IL using Aspire's phonemes.  If there's a choice, graphemes must be lower case.

# Outputs.
fileOuttxt = L + "/lang/clean.txt"  # Cleaned-up fileIntxt.  Keep only the chars in in.g2aspire.dict.  Eliminate >2 repeated chars.
fileOutdict = L + "/local/dict/lexicon.txt" # fileOuttxt's words, each with a pronunciation estimated from fileIndict.

# Extra outputs.
fileWords = L + "/local/dict/words.txt" # fileOuttxt's words.
filePhones = "/tmp/phones-" + L + ".txt" # fileOuttxt's phones, a subset of L/local/dict/nonsilence_phones.txt, which is the standard Aspire version.
fileMissingchars = "/tmp/letters-culled-by-cleaning-" + L + ".txt"    # Any characters in fileIntxt that were not in fileIndict.

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
            # M means mixed case.
            for wordM in re.split('[\d\s]+', line.strip()):
                if not wordM:
                    continue
                word = wordM.upper()
                if word == '<UNK>' or word == '</S>' or word == '<S>':
                    continue
                if wordM in prondict:
                    # This word already appeared in fileIntxt.
                    outwords.append(wordM)
                    continue
                rec = [] # Accumulate the word's letters that got g2p'd ok.
                pron = ''
                # Look up the *non-mixedcase* word's letters in the g2p.
                # Keep word and wordM in sync.
                while word:
                    # Find the longest-matching char sequence at the start of word[].
                    for n in range(min(len(word), len(g2p)), -1, -1):
                        if n == 0:
                            # word[] shrank to nothing, so the character word[0] was missing from the g2p,
                            # so delete it from cleaned output.
                            missingchars[word[0]] = 1
                            word = word[1:]
                            wordM = wordM[1:]
                            break
                        prefix = word[0:n]
                        prefixM = wordM[0:n]
                        if prefix in g2p[n-1]:
                            # Found this prefix.
                            # Keep this to cleaned output only if it's not a triple-repetition.
                            if len(rec)<2 or prefix != rec[-1] or rec[-1] != rec[-2]:
                                rec.append(prefixM)
                                pron += ' ' + g2p[n-1][prefix]
                            # Continue past the g2p-matched prefix.
                            word = word[n:]
                            wordM = wordM[n:]
                            break
                if rec:
                    rec = ''.join(rec)
                    prondict[rec] = pron
                    outwords.append(rec)
            if outwords:
                g.write(' '.join(outwords) + '\n')

# Write the prondict, and the lists of words, phones, and missing chars.
print('Writing {}'.format(fileOutdict))
with open(fileOutdict, 'w', encoding='utf-8') as f:
    for (k,v) in sorted(prondict.items()):
        f.write('%s %s\n' % (k,v))

print('Writing {}'.format(fileWords))
with open(fileWords, 'w', encoding='utf-8') as f:
    for (n,w) in enumerate(sorted(prondict.keys())):
        f.write('{}\n'.format(w))

print('Writing {}'.format(filePhones))
with open(filePhones, 'w') as f:
    for (n,p) in enumerate(sorted(phoneset.keys())):
        f.write('{}\n'.format(p))

print('Writing {}'.format(fileMissingchars))
with open(fileMissingchars, 'w', encoding='utf-8') as f:
    for k in sorted(missingchars.keys()):
        f.write(k + '\n')
