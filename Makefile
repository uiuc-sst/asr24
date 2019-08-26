all: lcs Makefile
	./lcs < trie1-scrips.txt
multicore: lcs Makefile
	rm -rf /tmp/fast
	mkdir /tmp/fast
	cp trie1-scrips.txt /tmp/fast/in
	cd /tmp/fast && split -n l/$$(nproc) in
	for f in /tmp/fast/x*; do (./lcs < $$f > /tmp/fast/y$$(basename $${f%}) &); done
	@echo "Wait a few minutes for the lcs's, then grep -h NI /tmp/fast/y* | sort > result."
lcs: lcs.cpp Makefile
	g++ -std=c++11 -O3 -Wall lcs.cpp -o $@
debug:
	g++ -std=c++11 -g -O0 -Wall lcs.cpp -o lcs
clean:
	rm -rf lcs
.PHONY: clean debug multicore
