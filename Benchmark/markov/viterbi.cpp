#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <ac_fixed.h>

typedef uint8_t tok_t;
typedef uint8_t state_t;
typedef int32_t step_t;

#define N_STATES  16
#define N_OBS     32
#define N_TOKENS  16

typedef ac_fixed<16,8,true,AC_TRN,AC_WRAP> prob_t;

int viterbi( tok_t obs[N_OBS],
             prob_t init[N_STATES],
             prob_t transition[N_STATES*N_STATES],
             prob_t emission[N_STATES*N_TOKENS],
             state_t path[N_OBS] );

struct bench_args_t {
  tok_t   obs[N_OBS];
  prob_t  init[N_STATES];
  prob_t  transition[N_STATES*N_STATES];
  prob_t  emission[N_STATES*N_TOKENS];
  state_t path[N_OBS];
};

#pragma hls_design top
int viterbi( tok_t obs[N_OBS],
             prob_t init[N_STATES],
             prob_t transition[N_STATES*N_STATES],
             prob_t emission[N_STATES*N_TOKENS],
             state_t path[N_OBS] )
{

#ifndef __SYNTHESIS__
  for (int t = 0; t < N_OBS; ++t) {
    if (obs[t] >= N_TOKENS) {
      fprintf(stderr,
              "[ERROR] obs[%d]=%u out of range (N_TOKENS=%d)\n",
              t, (unsigned)obs[t], N_TOKENS);
      return -1;
    }
  }
#endif

  prob_t  llike[N_OBS][N_STATES];
  step_t  t;
  state_t s;


  for (s = 0; s < N_STATES; s++) {
    llike[0][s] = init[s] + emission[s * N_TOKENS + obs[0]];
  }


  for (t = 1; t < N_OBS; t++) {
    for (state_t curr = 0; curr < N_STATES; curr++) {
      prob_t min_p = llike[t-1][0] +
                     transition[0 * N_STATES + curr] +
                     emission[curr * N_TOKENS + obs[t]];
      for (state_t prev = 1; prev < N_STATES; prev++) {
        prob_t p = llike[t-1][prev] +
                   transition[prev * N_STATES + curr] +
                   emission[curr * N_TOKENS + obs[t]];
        if (p < min_p) min_p = p;
      }
      llike[t][curr] = min_p;
    }
  }


  state_t min_s = 0;
  prob_t  min_p = llike[N_OBS-1][min_s];
  for (s = 1; s < N_STATES; s++) {
    prob_t p = llike[N_OBS-1][s];
    if (p < min_p) { min_p = p; min_s = s; }
  }
  path[N_OBS-1] = min_s;


  for (t = N_OBS - 2; t >= 0; --t) {
    state_t best = 0;
    prob_t  bp   = llike[t][0] + transition[0 * N_STATES + path[t+1]];
    for (s = 1; s < N_STATES; s++) {
      prob_t p = llike[t][s] + transition[s * N_STATES + path[t+1]];
      if (p < bp) { bp = p; best = s; }
    }
    path[t] = best;
  }

  return 0;
}
