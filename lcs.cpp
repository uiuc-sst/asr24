// Longest common substring.  (See Makefile.)

#include <algorithm>
#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <map>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

using namespace std;

// Later, for speed: to avoid mallocs,
// replace std::string with char[50] if that's long enough for all substrings.

// Longest common substring algorithm, via dynamic programming.
// But accumulate only substrings at least as long as lBest,
// because those are the only ones that the caller would keep.
vector<int> lcs(const string& a, const string& b, const int lBest=0) {
  const auto ca = a.size();
  const auto cb = b.size();
  int l[ca][cb]; // Lengths of substrings.
  memset(l, 0, sizeof(l));
  int lMax = 0;  // Max so far of l[][]'s.
  vector<int> iBests; // Longest substrings so far, of length lMax, as offsets into "a".
  //cout << "ca cb = " << ca << " " << cb << "\n";
  for (auto ia=0u; ia<ca; ++ia)
  for (auto ib=0u; ib<cb; ++ib) {
    if (a[ia] != b[ib])
      continue;
    // Found a substring.
    l[ia][ib] = (ia==0 || ib==0) ? 1 : l[ia-1][ib-1] + 1;
    if (l[ia][ib] > lMax) {
      // Found a longer substring.  Discard any shorter ones.
      lMax = l[ia][ib];
      iBests.clear();
    }
    if (lMax >= lBest && l[ia][ib] >= lMax) {
      // Accumulate the starting offset of another substring
      // of the same length (or longer: previous "if").
      // Omit duplicates.
      const int iNew = ia - lMax + 1;
      if (iBests.empty() || iBests.back() != iNew)
	iBests.push_back(iNew);
    }
  }
  iBests.insert(iBests.begin(), lMax); // Prepend the substrings' length to the array of offsets into a.
  //cout << "iBests "; for (auto i: iBests) cout << i << " "; cout << "\n";
  return iBests;
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

// trim from start (in place)
static inline void ltrim(string &s) {
  s.erase(s.begin(), find_if(s.begin(), s.end(), [](int ch) { return !isspace(ch); }));
}
// trim from end (in place)
static inline void rtrim(string &s) {
  s.erase(find_if(s.rbegin(), s.rend(), [](int ch) { return !isspace(ch); }).base(), s.end());
}
// trim from both ends (in place)
static inline void trim(string &s) {
  ltrim(s);
  rtrim(s);
}

map<string, string> pronsFromFile(const char* filename, char delimiter = '\t', bool fCull = false) {
  map<string, string> m;
  istringstream ss(strFromFile(filename));
  string line;
  while (getline(ss, line, '\n')) {
    // Convert to lower case.  May crash for non-ASCII multibyte UTF8.
    transform(line.begin(), line.end(), line.begin(), [](unsigned char c){ return tolower(c); });
    {
      // Omit words that begin with a nonletter.
      const auto firstchar = line[0];
      if (firstchar < 'a' || firstchar > 'z')
	continue;
    }
    // Split at delimiter into word and pronunciation.
    string word, pron;
    {
      istringstream iss(line);
      getline(iss, word, delimiter);
      getline(iss, pron); // omit delimiter?
      //cout << word << "\t\t---\t\t" << pron << "\n";;;;
      trim(pron);
    }
    if (fCull) {
      // Omit words chosen too often by LCS: short, vowelless, or consonantless.
      if (word.size() < 3 ||
	  word.find_first_of("aeiou") == string::npos ||
	  word.find_first_of("bcdfghjklmnpqrstvwxyz") == string::npos)
	continue;
      // todo: Soft-match like Soundex.
      ;;;;
    }
    // Deduplicate phones: split at spaces, then accumulate only nonduplicates.
    {
      istringstream iss(pron);
      string phonesNew, phonePrev;
      string phone;
      while (getline(iss, phone, ' ')) {
	if (phonePrev.empty() || phone != phonePrev)
	  phonesNew += phone + ' ';
	phonePrev = phone;
      }
      rtrim(phonesNew);
      pron = phonesNew;
    }

    m[word] = pron;
  }
  //;;;; tidy, cull, uniq, like lcs-kinyar.rb:72-92.
  return m;
}

// Split STDIN into lines, and each line into spaces.
vector<vector<string> > strsFromSTDIN() {
  vector<vector<string> > v;
  string line;
  while (getline(cin, line, '\n')) {
    istringstream iss(line);
    vector<string> tokens;
    string s;
    while (getline(iss, s, ' '))
      tokens.emplace_back(s);
    v.emplace_back(tokens);
  }
  return v;
}

// Does this string match the regex /[^_][^_]/ ?
// Hand-coded, because std::regex requires gcc 4.9, which is too new for Ubuntu 14.04.5.
// So find "not a _" and another one right thereafter.
bool onlySingleLettersLeft(const string& s) {
  const auto n = s.size();
  if (n < 2)
    return true;
  for (auto i=0u; i<n-2; ++i)
    if (s[i] != '_' && s[i+1] != '_')
      return false;
  return true;
}

// Levenshtein Distance Algorithm: C++ Implementation
// by Anders Sewerin Johansen, http://www.merriampark.com/ldcpp.htm, https://github.com/ekg/ogap
int levenshtein(const std::string source, const std::string target) {
  const int n = source.length();
  const int m = target.length();
  if (n == 0) {
    return m;
  }
  if (m == 0) {
    return n;
  }
  typedef std::vector< std::vector<int> > Tmatrix; 
  Tmatrix matrix(n+1);

  // Size the vectors in the 2.nd dimension. Unfortunately C++ doesn't
  // allow for allocation on declaration of 2.nd dimension of vec of vec
  for (int i = 0; i <= n; i++) {
    matrix[i].resize(m+1);
  }
  for (int i = 0; i <= n; i++) {
    matrix[i][0]=i;
  }
  for (int j = 0; j <= m; j++) {
    matrix[0][j]=j;
  }
  for (int i = 1; i <= n; i++) {
    const char s_i = source[i-1];
    for (int j = 1; j <= m; j++) {
      const char t_j = target[j-1];
      int cost;
      if (s_i == t_j) {
        cost = 0;
      }
      else {
        cost = 1;
      }
      const int above = matrix[i-1][j];
      const int left = matrix[i][j-1];
      const int diag = matrix[i-1][j-1];
      int cell = min( above + 1, min(left + 1, diag + cost));
      // Cover transposition, in addition to deletion,
      // insertion and substitution. This step is taken from:
      // Berghel, Hal ; Roach, David : "An Extension of Ukkonen's 
      // Enhanced Dynamic Programming ASM Algorithm"
      // (http://www.acm.org/~hlb/publications/asm/asm.html)
      if (i>2 && j>2) {
        int trans=matrix[i-2][j-2]+1;
        if (source[i-2]!=t_j) trans++;
        if (s_i!=target[j-2]) trans++;
        if (cell>trans) cell=trans;
      }
      matrix[i][j]=cell;
    }
  }
  return matrix[n][m];
}

int main() {
  const auto prondict(pronsFromFile("lcs1/train_all/cmudict-plain.txt", '\t'));
  cout << "Read prondict.\n";

  // Read transcriptions made of nonsense English words.
  const auto scrips = strsFromSTDIN();
  cout << "Read scrips.\n";

  // Apply pronunciations to each scrip, i.e. to "cougar aortic thrown" after NI1-2018-07-02_01_051.
  vector<pair<string, string> > scripsPron;
  for (auto scrip: scrips) {
    const string uttid(scrip[0]);
    scrip.erase(scrip.begin()); // Remove uttid.
    string phones;
    for (auto word: scrip)
      phones += prondict.at(word) + ' '; // .at() handles const map, unlike [].
    trim(phones);
    scripsPron.emplace_back(uttid, phones);
  }
  cout << "Pronounced scrips.\n";

  const auto prondictKinyar(pronsFromFile("kinyar-lexicon.txt", ' ', true));
  // abantu, aa b aa n t uw

  // To optimize, cull prondictKinyar.

  // Remap phones to single chars (in prondict and scrips) to avoid matching only part of a multichar phone like 'ao'.\n"; exit(1);

  typedef vector<string> MySet;
  unordered_map<string, MySet> h; // Map each pron to a collection of homonym words.
  unordered_map<string, string> lookup; // Map each word to its pron.
  for (auto& kv: prondictKinyar) {
    const auto& word = kv.first;
    const auto& pron = kv.second;
    //cout << "word " << word << " has pron " << pron << ".\n";
    auto& value = h[pron]; // Create empty MySet in h, if h doesn't already have "pron."
    value.emplace_back(word);
    lookup[word] = pron;
  }
  cout << "Prondict had " << prondictKinyar.size() << " pronunciations.\n";
  // Now lookup has all the pronunciations, and h has all the homonyms.
  // ;;;; Use lookup.  Use h.

  for (auto scrip: scripsPron) {
    const auto& uttid(scrip.first);
    auto phones(scrip.second);
    cout << uttid << "\t";
    if (phones.empty()) {
      cout << "\n";
      continue;
    }
    // lcs-kinyar.rb line 141
    typedef pair<int, string> AccPair;
    vector<AccPair> acc;
    // Keep matching words until phones has only isolated single letters left.
    while (!onlySingleLettersLeft(phones)) {
      cout << "\n" << phones << "\n";;;;
      string vbest;
      string vword;
      auto lenBest = 0;
      vector<pair< vector<string>, string>> bests; // Longest matches of phone strings.
      cout << "\nscanning prondict...\n";
      for (auto& kv: prondictKinyar) {
	const auto& word = kv.first;
	const auto& pron = kv.second;
	const auto rgLCS = lcs(phones, pron, lenBest);
	const auto len = rgLCS[0];
	const auto n = rgLCS.size() - 1;
	//cout << "len " << len << "    n " << n << "     w&p: " << word << " , " << pron << "\n";
	vector<string> substrs; // std::set isn't needed, because rgLCS lacks duplicates.
	for (auto i=1u; i<=n; ++i)
	  substrs.emplace_back(phones.substr(rgLCS[i], len));
	if (len > lenBest) {
	  lenBest = len;
	  bests = {{substrs, word}};
	  cout << "best " << lenBest << ", " << word << " , " << pron << "\n";
	}
	else if (len == lenBest) {
	  bests.emplace_back(substrs, word);
	}
      }
      cout << "scanned.\n";
      // lcs-kinyar.rb line 197
      typedef tuple<int, string, string> Close;
      vector<Close> closests;
      vector<Close> foo;
      //cout << "Bests are: "; for (const auto& ab: bests) { const auto& word = ab.second; cout << word << " "; } cout << "\n";
      for (const auto& ab: bests) {
	const auto& substrs = ab.first;
	const auto& word = ab.second;
	//cout << "Finding closests for " << word << " -- " << lookup[word] << "\n";
	int dMin = 9999;
	for (auto& s: substrs) {
	  const auto d = levenshtein(lookup[word], s);
	  //cout << d << " -- " << s << "\n";
	  if (d < dMin) {
	    dMin = d;
	    closests.clear();
	  }
	  if (d <= dMin)
	    closests.emplace_back(d, word, s);
	}
	closests.erase(unique(closests.begin(), closests.end()), closests.end()); // remove duplicates
	//cout << "Closests are:\n"; for (auto c: closests) cout << get<0>(c) << " -- " << get<1>(c) << ", " << get<2>(c) << "\n";
	/*
	// Not needed, because closests[*] has all the same d.
	closests.erase(remove_if(closests.begin(), closests.end(),
	  [&dMin](const Close& c) { return get<0>(c) == dMin; }), closests.end()); // Needed?
	*/

	// Choose one of these, randomly.
	// std::uniform_int_distribution would be overkill.
	// RAND_MAX is big enough to avoid sampling bias: typically, size() < 10.
	const auto i = rand() % closests.size();
	foo.emplace_back(closests[i]);
	//if (closests.size() > 1) cout << "Chose # " << i << "\n";
      }
      // Choose the member of foo with the smallest Levenshtein distance.
      const auto& bestOverall = *min_element(foo.begin(), foo.end(),
	  [](const Close& lhs, const Close& rhs) { return get<0>(lhs) < get<0>(rhs); });
      const auto chosenWord = get<1>(bestOverall);
      const auto chosenPhonestring = get<2>(bestOverall);
      cout << "chose d = " << get<0>(bestOverall) << ", " << chosenWord << "\n";
      // Re-find its phone string in phones.
      const auto i = phones.find(chosenPhonestring);
      //cout << "Mark as used the phones from " << i << " to " << i+chosenPhonestring.size() << "\n";
      acc.emplace_back(i, chosenWord);
      for (auto j = i; j < i+chosenPhonestring.size(); ++j)
	phones[j] = '_';
    }
    cout << "Only isolated single letters left.\n";

    // Sort acc by i.  Print its words.
    sort(acc.begin(), acc.end(),
      [](const AccPair& lhs, const AccPair& rhs) { return lhs.first < rhs.first; } );
    for (const auto iw: acc)
      cout << iw.second << " ";
    cout << "\n";
  }

  if (0) {
    const string s1("t o n z ɛ t ɪ n d ə t ɑ x t ə ɣ ə r j aː r ə m ɛ t m eː ɣ aː ɦ ɪ t s ɑ l s d ə b ɔ m d o r ə s d eː ɛ n ɪ s d");
    const string s2("avondetappe     ɑ v ɔ n d ə t ɑ p ə");
    const auto r = lcs(s1, s2);
    cout << "The LCS of '" << s1 << "'\nand '" << s2 << "'\nis '" << s1.substr(r[1], r[0]) << "', of " << r.size()-1 << " total.\n";
  }
  return 0;
}
