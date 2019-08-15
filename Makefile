all: lcs Makefile
	./lcs < trie1-scrips.txt
lcs: lcs.cpp Makefile
	g++ -std=c++11 -O3 -Wall lcs.cpp -o $@
