all: lcs
	./lcs
lcs: lcs.cpp
	g++ -std=c++11 -O3 lcs.cpp -o $@
