// Longest common substring.
// Compile with g++ -std=c++11.

#include <algorithm>
#include <fstream>
#include <iostream>
#include <set>
#include <sstream>
#include <string>
#include <vector>

using namespace std;

// Speedup: replace std::string with e.g. char[50] if that's long enough for all substrings,
// to avoid many little mallocs.

void findSubstrings(const string& word, set<string>& substrings) {
  // If l > 1000 or so, instead split word (at newlines) into an array, and call this function's sister.
  const int l = word.length();
  for (int i=0; i<l; ++i)
    for (int length = 1; length < l-i+1; ++length)
      substrings.insert(word.substr(i, length));
}

void findSubstrings(const vector<string>& words, set<string>& substrings) {
  // set<>::insert() becomes slow when set::size() > 1e6, and we need over 1e7.
  // Instead, fill a vector and then remove duplicates, even though that uses more RAM.
  cout << "Getting " << words.size() << ".\n"; // 133k
  int j = 0;
  vector<string> v;
  for (auto word: words) {
    ++j; if (j%5000 == 0) { cout << (double)j/words.size() << "\r"; cout.flush(); }
    const int l = word.size();
    for (int i=0; i<l; ++i)
      for (int length = 1; length < l-i+1; ++length)
	v.emplace_back(word.substr(i, length));
  }
#if 0
  // This builds 6x faster, but its often-called set_intersection() is much slower.
  // #include <unordered_set>
  substrings = unordered_set<string>(make_move_iterator(v.begin()), make_move_iterator(v.end()));
#else
  cout << "Sorting " << v.size() << ".\n"; // 41M
  sort(v.begin(), v.end());
  cout << "Uniqing.\n";
  v.erase(unique(v.begin(), v.end()), v.end());
  cout << "Copying " << v.size() << ".\n"; // 16M
  substrings = std::set<string>(std::make_move_iterator(v.begin()), std::make_move_iterator(v.end()));
#endif
}

struct size_less {
  template<class T> bool operator()(T const &a, T const &b) const { return a.size() < b.size(); }
};

// Brute force, but findSubstrings(s2) can be done just once and then used for each line of the prondict.
//
// Dynamic programming needs a 2d array of prondictSize * lineSize, 7M * 100, about 7 GB.  Small enough.
// Actually, smaller.  Run lcs() on each line of s2, collect those results, report the longest one.
string lcs(const string& s1, const string& s2) {
  set<string> firstSubstrings, secondSubstrings;
  cout << "Build substrings for " << s1.size() << " chars.\n";
  findSubstrings(s1, firstSubstrings);
  cout << "Build substrings for " << s2.size() << " chars.\n";
  findSubstrings(s2, secondSubstrings);
  cout << "Intersecting.\n";
  set<string> common;
  set_intersection(firstSubstrings.begin(), firstSubstrings.end(), 
    secondSubstrings.begin(), secondSubstrings.end(),
    inserter(common, common.begin()));
  if (common.empty())
    return "";
  return *max_element(common.begin(), common.end(), size_less());
}

string lcs(const string& s1, const vector<string>& s2) {
  set<string> firstSubstrings, secondSubstrings;
  cout << "Build substrings for " << s1.size() << " chars.\n";
  findSubstrings(s1, firstSubstrings);
  cout << "Build substrings for " << s2.size() << " words.\n";
  findSubstrings(s2, secondSubstrings);
  cout << "Intersecting.\n";
  set<string> common;
  set_intersection(firstSubstrings.begin(), firstSubstrings.end(), 
    secondSubstrings.begin(), secondSubstrings.end(),
    inserter(common, common.begin()));
  if (common.empty())
    return "";
  return *max_element(common.begin(), common.end(), size_less());
}

string strFromFile(const char* fileName) {
  ifstream ifs(fileName, ios::in | ios::binary | ios::ate);
  ifstream::pos_type fileSize = ifs.tellg();
  ifs.seekg(0, ios::beg);
  vector<char> bytes(fileSize);
  ifs.read(bytes.data(), fileSize);
  return string(bytes.data(), fileSize);
}

vector<string> strsFromFile(const char* filename) {
  istringstream ss(strFromFile(filename));
  vector<string> v;
  string line;
  while (getline(ss, line, '\n'))
    v.emplace_back(line);
  return v;
}

int main() {
  {
    string s1("t o n z ɛ t ɪ n d ə t ɑ x t ə ɣ ə r j aː r ə m ɛ t m eː ɣ aː ɦ ɪ t s ɑ l s d ə b ɔ m d o r ə s d eː ɛ n ɪ s d");
    string s2("avondetappe     ɑ v ɔ n d ə t ɑ p ə");
    cout << "The LCS of '" << s1 << "'\nand '" << s2 << "'\nis '" << lcs(s1, s2) << "'.\n";
  }
  {
    auto s1("AH D AH M AH T");
    auto s2(strsFromFile("lcs1/train_all/cmudict-plain.txt"));
    cout << "Read prondict.\n";
    auto s3(s2[999]);
    cout << "Finding an LCS for '" << s3 << "'.\n";
    cout << "The LCS is '" << lcs(s1, s3) << "'.\n";
    cout << "Finding a fancy LCS.\n";
    cout << "Fancy LCS is '" << lcs(s1, s2) << "'.\n";
  }
    return 0;
  }
