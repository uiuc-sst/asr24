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

// Longest Common Substring algorithm, via dynamic programming.
// Return the length of the substrings, followed by their offsets into "a."
// But accumulate only substrings at least as long as lBest,
// because those are the only ones that the caller would keep.
vector<int> lcs(const string& a, const string& b, const int lBest=0) {
  const auto ca = a.size();
  const auto cb = b.size();
  int l[ca][cb]; // Lengths of substrings.
  memset(l, 0, sizeof l);
  int lMax = 0;  // Max so far of l[][]'s.
  vector<int> iBests; // Longest substrings so far, of length lMax, as offsets into "a".
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
  iBests.insert(iBests.begin(), lMax); // Prepend the substrings' length to the vector of offsets into a.
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

// Restrict phones.  Map rare ones to common ones.  Map into the prondict.
// Map vowels to ah, eh, uw.
void soft(string& phone) {
  static const map<string, string> soundex = {
    {"aw", "ah"},
    {"s", "ch"},
    {"sh", "ch"},
    {"jh", "ch"},
    {"iy", "eh"},
    {"dh", "t"},
    {"er", "eh"},
    {"ae", "ah"},
    {"ao", "ah"},
    {"b", "p"},
    {"ih", "eh"},
    {"uh", "ah"},
    {"aa", "ah"},
    {"ay", "ah"},
    {"ow", "uw"},
    {"ey", "ah"}
  };
  const auto it = soundex.find(phone);
  if (it != soundex.end())
    phone = it->second;
}

// Remap a phone to a single char (in prondict and scrips) to avoid matching only part of a multichar phone like 'ao'.
void remap(string& phone) {
  static const map<string, string> tidy = {
    {"ah", "0"},
    {"ch", "1"},
    {"d",  "2"},
    {"eh", "3"},
    {"f",  "4"},
    {"g",  "5"},
    {"hh", "6"},
    {"k",  "7"},
    {"l",  "8"},
    {"m",  "9"},
    {"n",  "a"},
    {"ng", "b"},
    {"p",  "c"},
    {"sil","d"},
    {"t",  "e"},
    {"th", "f"},
    {"uw", "g"},
    {"v",  "h"},
    {"w",  "i"},
    {"y",  "j"},
    {"z",  "k"},
    {"r",  "l"},
    {" ",  ""}
  };
  const auto it = tidy.find(phone);
  if (it != tidy.end())
    phone = it->second;
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
      //if (!fCull) cout << word << "\t\t---\t\t" << pron << "\n";;;;
      trim(pron);
    }
    if (fCull) {
      // Omit words chosen too often by LCS: short, vowelless, or consonantless.
      if (word.size() < 3 ||
	  word.find_first_of("aeiou") == string::npos ||
	  word.find_first_of("bcdfghjklmnpqrstvwxyz") == string::npos)
	continue;
    }
    // Deduplicate phones: split at spaces, then accumulate only nonduplicates.
    {
      istringstream iss(pron);
      string phonesNew, phonePrev;
      string phone;
      while (getline(iss, phone, ' ')) {
	soft(phone);
	remap(phone);
	trim(phone);
	if (phonePrev.empty() || phone != phonePrev)
	  phonesNew += phone; //+' ';
	phonePrev = phone;
      }
      rtrim(phonesNew);
      pron = phonesNew;
      //if (!fCull) cout << "\t\t\t\t'" << pron << "'\n";
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

// Levenshtein distance
int levenshtein(const string& si, const string& sj) {
  const int n = si.length();
  const int m = sj.length();
  if (n == 0) return m;
  if (m == 0) return n;
  vector<vector<int>> M(n+1, vector<int>(m+1));
  for (auto i = 0; i <= n; i++) M[i][0]=i;
  for (auto j = 0; j <= m; j++) M[0][j]=j;
  for (auto i = 1; i <= n; i++) {
    const auto s_i = si[i-1];
    for (int j = 1; j <= m; j++) {
      const auto t_j = sj[j-1];
      const auto cost = s_i == t_j ? 0 : 1;
      const auto& above = M[i-1][j];
      const auto& left  = M[i][j-1];
      const auto& diag  = M[i-1][j-1];
      const auto cell = min(above + 1, min(left + 1, diag + cost));
      // Exclude transposition, because although it's easy for typed letters,
      // it's rare for spoken phones.
#if 0
      // Include transposition, as well as deletion, insertion and substitution.
      // From Berghel & Roach, "An Extension of Ukkonen's Enhanced Dynamic Programming ASM Algorithm."
      if (i>2 && j>2) {
        auto trans = M[i-2][j-2] + 1;
        if (si[i-2] != t_j) ++trans;
        if (s_i != sj[j-2]) ++trans;
        if (cell > trans)
	  cell = trans;
      }
#endif
      M[i][j] = cell;
    }
  }
  return M[n][m];
}

#if 0
void replaceAllInstances(string& s, const string& sOld, const string& sNew) {
  const auto cOld = sOld.length();
  const auto cNew = sNew.length();
  size_t i = 0u;
  while ((i = s.find(sOld, i)) != string::npos) {
     s.replace(i, cOld, sNew);
     i += cNew;
  }
}
#endif

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
      phones += prondict.at(word); //+' '; // .at() handles const map, unlike [].
    trim(phones);
    scripsPron.emplace_back(uttid, phones);
  }
  cout << "Pronounced scrips.\n";

  const auto prondictKinyar(pronsFromFile("kinyar-lexicon.txt", ' ', true));
  // abantu, aa b aa n t uw

  // To optimize, cull prondictKinyar.

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

#if 0
  // Dump the homonyms.
  for (const auto& kv: h) {
    cout << kv.first << "\t\t\t";
    for (const auto& word: kv.second) cout << word << " ";
    cout << "\n";
  }
#endif

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
      //cout << "\nscanning prondict...\n";
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
	  //cout << "best " << lenBest << ", " << word << " , " << pron << "\n";
	}
	else if (len == lenBest) {
	  bests.emplace_back(substrs, word);
	}
      }
      //cout << "scanned.\n";
      // lcs-kinyar.rb line 197
      typedef tuple<int, string, string> Close;
      vector<Close> closests;
      vector<Close> candidates;
      //cout << "Bests are: "; for (const auto& ab: bests) { const auto& word = ab.second; cout << word << " "; } cout << "\n";
      for (const auto& ab: bests) {
	const auto& substrs = ab.first;
	const auto& word = ab.second;
	//cout << "Finding closests for " << word << " -- " << lookup[word] << "\n";
	auto dMin = 9999;
	for (auto& s: substrs) {
	  const auto d = levenshtein(lookup[word], s);
	  if (d < dMin) {
	    dMin = d;
	    closests.clear();
	  }
	  if (d <= dMin)
	    closests.emplace_back(d, word, s);
	}
	closests.erase(unique(closests.begin(), closests.end()), closests.end()); // remove duplicates
	//cout << "Closests are:\n"; for (auto c: closests) cout << get<0>(c) << " -- " << get<1>(c) << ", " << get<2>(c) << "\n";

	// Choose one of these, randomly.
	// std::uniform_int_distribution would be overkill.
	// RAND_MAX is big enough to avoid sampling bias: typically, size() < 10.
	candidates.emplace_back(closests[rand() % closests.size()]);
      }
      // Choose the candidate with the smallest Levenshtein distance.
      const auto& bestOverall = *min_element(candidates.begin(), candidates.end(),
	[](const Close& lhs, const Close& rhs) { return get<0>(lhs) < get<0>(rhs); });
      const auto& chosenWord = get<1>(bestOverall);
      const auto& chosenPhonestring = get<2>(bestOverall);
      cout << "Chose d = " << get<0>(bestOverall) << ", " << chosenWord << "\n";
      // Re-find its phone string in phones.
      const auto iPhone = phones.find(chosenPhonestring);
      // Usually, chosenPhonestring won't be in h[], because it's usually a
      // proper subset of the pronunciation of some words, not the exact
      // pronunciation of any particular words.
      // Instead of a fancier lookup, for the common case just use chosenWord.
      // It's often enough the best choice, anyways.
      const auto& homonyms = h[chosenPhonestring];
      const auto& homonym = homonyms.empty() ? chosenWord : homonyms[rand() % homonyms.size()];
      acc.emplace_back(iPhone, homonym);
#if 0
      // Replace the used phones, from i to i+chosenPhonestring.size(),
      // with a single _ rather than a sequence of _'s,
      // so later lcs()'s have shorter inputs and are thus faster.
      phones[i] = '_';
      phones.erase(i+1, chosenPhonestring.size()-1);
      // Even faster: coalesce consecutive _'s from previous replacements.  __ to _ suffices.
      // Splitting phones into separate strings and lcs'ing each one would be doubtfully faster yet.
      replaceAllInstances(phones, "__", "_");
#else
      // Mark each used phone.  Slower, but less overhead than mapping the offset in a shrunken phones[]
      // to the offset in the original.  That offset is what we sort acc by, to reconstruct the order of words.
      for (auto j = iPhone; j < iPhone+chosenPhonestring.size(); ++j)
	phones[j] = '_';
#endif
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
