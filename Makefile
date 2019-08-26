all: lcs-kinyar Makefile
	@echo lcs-kinyar takes about 95 minutes singlecore.
	./lcs-kinyar < trie1-scrips.txt
multicore: lcs-kinyar Makefile
	rm -rf /tmp/fast
	mkdir /tmp/fast
	cp trie1-scrips.txt /tmp/fast/in
	cd /tmp/fast && split -n l/$$(nproc) in
	for f in /tmp/fast/x*; do (./lcs-kinyar < $$f > /tmp/fast/y$$(basename $${f%}) &); done
	@echo "Wait 5 minutes for the lcs's, then grep -h NI /tmp/fast/y* | sort > result."
lcs-kinyar: lcs-kinyar.cpp Makefile
	g++ -std=c++11 -O3 -Wall lcs-kinyar.cpp -o $@
debug:
	g++ -std=c++11 -g -O0 -Wall lcs-kinyar.cpp -o lcs-kinyar
clean:
	rm -rf lcs-kinyar
.PHONY: clean debug multicore
