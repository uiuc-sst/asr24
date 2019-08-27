all:
	@echo For targets, see the Makefile.

all-sinhal: lcs-sinhal Makefile
	@echo lcs-sinhal converts 2271 nonsense-English-word transcriptions, totalling 236 KB, to Sinhalese.
	./lcs-sinhal < trie2-scrips.txt

all-kinyar: lcs-kinyar Makefile
	@echo lcs-kinyar in 95 minutes converts 1452 nonsense-English-word transcriptions, totalling 217 KB, to Kinyarwanda.
	./lcs-kinyar < trie1-scrips.txt

multicore-sinhal: lcs-sinhal Makefile
	rm -rf /tmp/fast
	mkdir /tmp/fast
	cp trie2-scrips.txt /tmp/fast/in
	cd /tmp/fast && split -n l/$$(nproc) in
	for f in /tmp/fast/x*; do (./lcs-sinhal < $$f > /tmp/fast/y$$(basename $${f%}) &); done
	@echo "Wait 5 minutes for the lcs's, then grep -h NI /tmp/fast/y* | sort > result."

multicore-kinyar: lcs-kinyar Makefile
	rm -rf /tmp/fast
	mkdir /tmp/fast
	cp trie1-scrips.txt /tmp/fast/in
	cd /tmp/fast && split -n l/$$(nproc) in
	for f in /tmp/fast/x*; do (./lcs-kinyar < $$f > /tmp/fast/y$$(basename $${f%}) &); done
	@echo "Wait 5 minutes for the lcs's, then grep -h NI /tmp/fast/y* | sort > result."

lcs-sinhal: lcs-sinhal.cpp Makefile
	g++ -std=c++11 -O3 -Wall lcs-sinhal.cpp -o $@
lcs-kinyar: lcs-kinyar.cpp Makefile
	g++ -std=c++11 -O3 -Wall lcs-kinyar.cpp -o $@

debug:
	g++ -std=c++11 -g -O0 -Wall lcs-kinyar.cpp -o lcs-kinyar
	g++ -std=c++11 -g -O0 -Wall lcs-sinhal.cpp -o lcs-kinyar
clean:
	rm -rf lcs-kinyar lcs-sinhal

.PHONY: clean debug multicore
