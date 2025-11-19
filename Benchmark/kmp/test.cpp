// test.cpp
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <string>
#include <sstream>
#include <vector>
#include <fstream>
#include <ac_int.h>

#define PATTERN_SIZE 4
#define STRING_SIZE  (1041)

int kmp(char pattern[PATTERN_SIZE],
        char input[STRING_SIZE],
        ac_int<2,false>  kmpNext[PATTERN_SIZE],
        ac_int<11,false> n_matches[1]);

static inline void fill_char(char* s, char c){
  for(int i=0;i<STRING_SIZE;i++) s[i]=c;
}
static inline void write_pattern(char* s, int pos, const char p[PATTERN_SIZE]){
  for(int i=0;i<PATTERN_SIZE;i++) s[pos+i]=p[i];
}

int main(){
  std::vector<std::string> local_results;
  bool global_pass = true;

  struct TV { std::string name; char pattern[PATTERN_SIZE]; int golden; } tv[5];

  tv[0] = {"T1_ABCD_scattered", {'A','B','C','D'}, 7};
  tv[1] = {"T2_AAAA_runs",      {'A','A','A','A'}, 64};
  tv[2] = {"T3_ABAB_repeat200", {'A','B','A','B'}, 99};
  tv[3] = {"T4_DCBA_nomatch",   {'D','C','B','A'}, 0};
  tv[4] = {"T5_ABCD_tightpack", {'A','B','C','D'}, 560};

  for(int t=0;t<5;t++){
    char pattern[PATTERN_SIZE];
    char input[STRING_SIZE];
    ac_int<2,false>  kmpNext[PATTERN_SIZE];
    ac_int<11,false> n_matches[1];

    for(int i=0;i<PATTERN_SIZE;i++) pattern[i]=tv[t].pattern[i];

    if(t==0){
      fill_char(input,'Z');

      int pos_list[7] = {100, 300, 600, 700, 880, 980, 1000};
      for(int k=0;k<7;k++) write_pattern(input,pos_list[k],pattern);
    }else if(t==1){
      fill_char(input,'B');
      for(int i=0;i<20;i++) input[i]='A';
      for(int i=1000; i<1050 && i<STRING_SIZE; i++) input[i]='A';
    }else if(t==2){
      fill_char(input,'Z');
      for(int i=0;i<200 && i<STRING_SIZE;i++)
        input[i] = (i&1)?'B':'A';
    }else if(t==3){
      fill_char(input,'A');
    }else{
      fill_char(input,'X');
      for (int i=0; i+PATTERN_SIZE<=STRING_SIZE; i+=PATTERN_SIZE){
        input[i+0]='A'; input[i+1]='B'; input[i+2]='C'; input[i+3]='D';
      }
    }

    kmp(pattern,input,kmpNext,n_matches);
    int actual = (int)n_matches[0].to_uint();
    int golden = tv[t].golden;
    bool pass = (actual==golden);
    global_pass &= pass;

    std::stringstream ss;
    ss << "LOCAL_CHECK" << (t+1) << ": " << (pass?"PASS":"FAIL")
       << ", Input: " << tv[t].name
       << ", Actual Output: " << actual
       << ", Golden Output: " << golden;
    local_results.push_back(ss.str());
    std::printf("%s\n", ss.str().c_str());
  }

  std::ofstream ofs("result.txt");
  if(ofs.is_open()){
    ofs << "GLOBAL_CHECK: " << (global_pass ? "PASS" : "FAIL") << "\n";
    for(const auto& s: local_results) ofs << s << "\n";
    ofs.close();
  }else{
    std::printf("Error: Could not open result.txt for writing.\n");
  }

  return global_pass?0:1;
}
