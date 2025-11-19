#include <cstdio>
#include <cstdint>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <iomanip>
#include <algorithm>
#include "mc_scverify.h"

extern "C" void mips_sort(const int A_in[8], int out[8], int* n_inst_out);

std::string to_int_string(const int* data, size_t len) {
  std::stringstream ss;
  for (size_t i = 0; i < len; ++i) {
    ss << data[i];
    if (i + 1 < len) ss << " ";
  }
  return ss.str();
}

CCS_MAIN(int argc, char *argv[]) {
  const std::vector<std::vector<int>> inputs = {
    {22, 5, -9, 3, -17, 38, 0, 11},
    {7, 6, 5, 4, 3, 2, 1, 0},
    {100, -50, 25, -75, 0, 50, -100, 75},
    {9, 9, 9, 1, 1, 1, 5, 5},
    {-5, -10, -3, -8, -1, -7, -2, -4}
  };
  const std::vector<std::vector<int>> goldens = {
    {-17, -9, 0, 3, 5, 11, 22, 38},
    {0, 1, 2, 3, 4, 5, 6, 7},
    {-100, -75, -50, 0, 25, 50, 75, 100},
    {1, 1, 1, 5, 5, 9, 9, 9},
    {-10, -8, -7, -5, -4, -3, -2, -1}
  };

  bool global_pass = true;
  std::vector<std::string> local_results;

  for (size_t i = 0; i < inputs.size(); ++i) {
    int out[8];
    int n_inst = 0;

    int inbuf[8];
    std::copy(inputs[i].begin(), inputs[i].end(), inbuf);

    mips_sort(inbuf, out, &n_inst);

    bool local_pass = true;
    for (int j = 0; j < 8; ++j) {
      if (out[j] != goldens[i][j]) {
        local_pass = false;
        break;
      }
    }
    if (!local_pass) global_pass = false;

    std::string input_str = to_int_string(inbuf, 8);
    std::string actual_str = to_int_string(out, 8);
    std::string golden_str = to_int_string(goldens[i].data(), goldens[i].size());

    std::stringstream result_line;
    result_line << "LOCAL_CHECK" << (i + 1) << ": "
                << (local_pass ? "PASS" : "FAIL")
                << ", Input: " << input_str
                << ", Actual Output: " << actual_str
                << ", Golden Output: " << golden_str
                << ", N_INST: " << n_inst;

    local_results.push_back(result_line.str());
    std::printf("%s\n", result_line.str().c_str());
  }

  std::ofstream outfile("results.txt");
  if (outfile.is_open()) {
    outfile << "GLOBAL_CHECK: " << (global_pass ? "PASS" : "FAIL") << std::endl;
    for (const auto& line : local_results) {
      outfile << line << std::endl;
    }
    outfile.close();
    std::printf("\nResults saved to results.txt\n");
  } else {
    std::printf("\nError: Could not open results.txt for writing.\n");
  }

  CCS_RETURN(global_pass ? 0 : 1);
}
