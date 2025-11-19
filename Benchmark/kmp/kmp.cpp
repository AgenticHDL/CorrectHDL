// kmp.c
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <ac_int.h>

#define PATTERN_SIZE 4
#define STRING_SIZE  (1041)


int kmp(char pattern[PATTERN_SIZE],
        char input[STRING_SIZE],
        ac_int<2,false>  kmpNext[PATTERN_SIZE],
        ac_int<11,false> n_matches[1]);

struct bench_args_t {
  char pattern[PATTERN_SIZE];
  char input[STRING_SIZE];
  ac_int<2,false>  kmpNext[PATTERN_SIZE];
  ac_int<11,false> n_matches[1];
};


typedef ac_int<11,false> u11_t;  // 0..1241
typedef ac_int<3,false>  u3_t;   // 0..4
typedef ac_int<2,false>  u2_t;   // 0..3


static inline u3_t tok(char c){
  return (c=='A') ? (u3_t)0 :
         (c=='B') ? (u3_t)1 :
         (c=='C') ? (u3_t)2 :
         (c=='D') ? (u3_t)3 : (u3_t)4;
}


static void CPF_local(const char pat[PATTERN_SIZE], u2_t pi[PATTERN_SIZE]){
  u2_t k = 0;
  pi[0]  = 0;

  u3_t ptk[PATTERN_SIZE];
  for(u3_t t=0; t<PATTERN_SIZE; ++t) ptk[t] = tok(pat[t]);

  for(u3_t q=1; q<PATTERN_SIZE; ++q){
    while((k>0) && (ptk[k] != ptk[q])) k = pi[k-1];
    if(ptk[k] == ptk[q]) k = (u2_t)(k+1);
    pi[q] = k;
  }
}

#pragma hls_design top
#pragma design_goal area
int kmp(char pattern[PATTERN_SIZE],
        char input[STRING_SIZE],
        ac_int<2,false>  kmpNext[PATTERN_SIZE],
        ac_int<11,false> n_matches[1])
{

  u2_t* pi = kmpNext;


  u3_t ptk[PATTERN_SIZE];
  for(u3_t t=0; t<PATTERN_SIZE; ++t) ptk[t] = tok(pattern[t]);


  CPF_local(pattern, pi);


  u3_t  q  = 0;
  u11_t nm = 0;

  for(u11_t i=0; i<STRING_SIZE; ++i){
    u3_t ib = tok(input[i]);           // 8bit -> 3bit

    while((q>0) && (ptk[q] != ib)) q = (u3_t)pi[q-1];
    if(ptk[q] == ib) q = (u3_t)(q+1);
    if(q >= PATTERN_SIZE){
      nm = (u11_t)(nm + 1);
      q  = (u3_t)pi[q-1];
    }
  }

  n_matches[0] = (ac_int<11,false>)nm;
  return 0;
}
