all: lcs Makefile
	./lcs < trie1-scrips.txt
lcs: lcs.cpp Makefile
	g++ -std=c++11 -O3 -Wall lcs.cpp -o $@
debug:
	g++ -std=c++11 -g -O0 -Wall lcs.cpp -o lcs
clean:
	rm -rf lcs
.PHONY: clean debug
