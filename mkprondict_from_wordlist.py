#!/usr/bin/env python3

import sys, os, re

USAGE='''USAGE: mkprondict_from_wordlist.py <newlangdir>.  Make prondict from input wordlist, which is assumed to already match the language model.'''
if len(sys.argv) != 2:
    print(USAGE)
    exit(1)
L = sys.argv[1]

# Inputs.
fileInwords = L + "/local/dict/words.txt"   # Input wordlist, one word per line.
fileIndict = L + "/train_all/g2aspire.txt"    # A g2p for IL using Aspire's phonemes.  If there's a choice, graphemes must be lower case.

# Outputs.
fileOutdict = L + "/local/dict/lexicon.txt" # fileOuttxt's words, each with a pronunciation estimated from fileIndict.

# Extra outputs.
filePhones = "/tmp/phones-" + L + ".txt" # fileOuttxt's phones, a subset of L/local/dict/nonsilence_phones.txt, which is the standard Aspire version.

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

abort = False
# Read fileInwords.  Convert words.
prondict = {}
with open(fileInwords, 'r', encoding='utf-8') as f:
    ok = True
    print('Making prondict from %s.' % fileInwords)
    for line in f:
        # Assume one word per line.  Strip off newline, and uppercase it.
        wordOriginal = wordM = line.rstrip() # M means mixed case.
        if not wordM:
            continue
        word = wordM.upper()
        if word == '<UNK>' or word == '</S>' or word == '<S>':
            continue
        if wordM in prondict:
            print('Wordlist ' + fileInwords + ' has invalid duplicate word ' + wordM + '.')
            abort = True
            continue
        rec = [] # Accumulate the word's letters that got g2p'd ok.
        pron = ''
        # Look up the *non-mixedcase* word's letters in the g2p.
        # Keep word and wordM in sync.
        while word:
            # Find the longest-matching char sequence at the start of word[].
            for n in range(min(len(word), len(g2p)), -1, -1):
                if n == 0:
                    # No prefix matched, so the character word[0] was missing from the g2p.
                    print('Wordlist ' + fileInwords + ' has g2p-missing grapheme "' + word[0].lower() + '" in word "' + wordOriginal + '"')
                    #print(word[0].lower())
                    ok = False
                    # If the grapheme is really obscure, in a loanword, such as Ḥ of alḤasan in the context of Kinyarwanda,
                    # then correct the grapheme in the supposedly clean wordlist,
                    # instead of growing the g2p or extending this source code.
                    word = ""
                    rec = [] # Just remove this word from the g2p.
                    break
                prefix = word[0:n]
                prefixM = wordM[0:n]
                if prefix in g2p[n-1]:
                    # Found this prefix.
                    rec.append(prefixM)
                    pron += ' ' + g2p[n-1][prefix]
                    # Continue past the g2p-matched prefix.
                    word = word[n:]
                    wordM = wordM[n:]
                    break
        if rec:
            prondict[''.join(rec)] = pron
if not ok:
    print('Aborting due to missing graphemes.')
    exit(1)
if abort:
    print('Aborting due to duplicate words.')
    exit(1)

# Write the prondict and the phone list.
print('Writing {}'.format(fileOutdict))
with open(fileOutdict, 'w', encoding='utf-8') as f:
    for (k,v) in sorted(prondict.items()):
        f.write('%s %s\n' % (k,v))

print('Writing {}'.format(filePhones))
with open(filePhones, 'w') as f:
    for (n,p) in enumerate(sorted(phoneset.keys())):
        f.write('{}\n'.format(p))
