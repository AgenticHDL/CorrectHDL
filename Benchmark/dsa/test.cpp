#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <cstring>

#define ALEN 6
#define BLEN 6

#ifdef __cplusplus
extern "C"
#endif 
void needwun(char SEQA[ALEN], char SEQB[BLEN],
             char alignedA[ALEN+BLEN], char alignedB[ALEN+BLEN],
             int M[(ALEN+1)*(BLEN+1)], char ptr[(ALEN+1)*(BLEN+1)]);

// ----- hash utils -----
static uint64_t djb2_hash_bytes(const unsigned char* data, size_t n) {
  uint64_t h = 5381u;
  for (size_t i = 0; i < n; ++i) h = ((h << 5) + h) + data[i];
  return h;
}
static std::string digest_to_hex(uint64_t x) {
  static const char* hex = "0123456789abcdef";
  std::string s(16, '0');             // 64-bit -> 16 hex chars
  for (int i = 15; i >= 0; --i) {
    s[i] = hex[x & 0xF];
    x >>= 4;
  }
  return s;
}

int main() {
  const int W = (ALEN + 1) * (BLEN + 1);
  const uint64_t n_inst = (uint64_t)ALEN * (uint64_t)BLEN; // 100


  std::vector<std::pair<std::string, std::string>> tests;
  tests.push_back({"GATTACA", "GCATGCU"});
  tests.push_back({"AAAAACCCCTTTTGGGG", "AAAACCCGGTT"});
  tests.push_back({"NEEDLEMANWUNSCH", "NEWMANWINS"});
  tests.push_back({"HELLOWORLD", "YELLOWBIRD"});
  tests.push_back({"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "AAAAAAAAAAAAAAAAAAAAAAAATTTTTTTT"});


  static const uint64_t GOLDEN_HASHES[5] = {
    0x5c7f9b08fbe64c99ULL,
    0xb0be548b1686ae96ULL,
    0x155c83c11c948b09ULL,
    0x0e9ffbf35be71d03ULL,
    0x0000000000000000ULL
  };

  bool global_pass = true;
  std::vector<std::string> local_results;

  for (size_t t = 0; t < tests.size(); ++t) {

    std::vector<char> A(ALEN, 0), B(BLEN, 0);
    const std::string& sa = tests[t].first;
    const std::string& sb = tests[t].second;
    size_t copy_a = sa.size() < (size_t)ALEN ? sa.size() : (size_t)ALEN;
    size_t copy_b = sb.size() < (size_t)BLEN ? sb.size() : (size_t)BLEN;
    std::memcpy(A.data(), sa.data(), copy_a);
    std::memcpy(B.data(), sb.data(), copy_b);


    std::vector<char> alignedA_act(ALEN + BLEN, 0), alignedB_act(ALEN + BLEN, 0);
    std::vector<int>  M(W, 0);
    std::vector<char> P(W, 0);


    needwun(A.data(), B.data(), alignedA_act.data(), alignedB_act.data(), M.data(), P.data());


    uint64_t actual = 0;
    actual ^= djb2_hash_bytes(reinterpret_cast<const unsigned char*>(alignedA_act.data()), alignedA_act.size());
    actual ^= djb2_hash_bytes(reinterpret_cast<const unsigned char*>(alignedB_act.data()), alignedB_act.size());


    const uint64_t golden = GOLDEN_HASHES[t];
    bool local_pass = (actual == golden);
    if (!local_pass) global_pass = false;


    const std::string msg = tests[t].first + "|" + tests[t].second;
    const std::string actual_str = digest_to_hex(actual);
    const std::string golden_str = digest_to_hex(golden);

    std::stringstream result_line;
    result_line << "LOCAL_CHECK" << (t + 1) << ": "
                << (local_pass ? "PASS" : "FAIL")
                << ", Input: " << msg
                << ", Actual Output: " << actual_str
                << ", Golden Output: " << golden_str
                << ", N_INST: " << n_inst;

    local_results.push_back(result_line.str());
    std::printf("%s\n", result_line.str().c_str());
  }


  std::ofstream outfile("results.txt");
  if (outfile.is_open()) {
    outfile << "GLOBAL_CHECK: " << (global_pass ? "PASS" : "FAIL") << std::endl;
    for (const auto& line : local_results) outfile << line << std::endl;
    outfile.close();
    std::printf("\nResults saved to results.txt\n");
  } else {
    std::printf("\nError: Could not open results.txt for writing.\n");
  }
  return global_pass ? 0 : 1;
}
