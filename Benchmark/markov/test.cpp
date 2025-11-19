#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>
#include <sstream>
#include <fstream>
#include <cassert>
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

static std::string vec_u8_to_str(const tok_t* a, int n){
  std::ostringstream oss;
  for(int i=0;i<n;i++){ if(i) oss<<' '; oss<<(unsigned)a[i]; }
  return oss.str();
}
static std::string vec_state_to_str(const state_t* a, int n){
  std::ostringstream oss;
  for(int i=0;i<n;i++){ if(i) oss<<' '; oss<<(unsigned)a[i]; }
  return oss.str();
}


static void build_smooth_hmm(prob_t init[N_STATES],
                             prob_t transition[N_STATES*N_STATES],
                             prob_t emission[N_STATES*N_TOKENS]){
  for(int s=0;s<N_STATES;s++) init[s] = prob_t(0);
  for(int i=0;i<N_STATES;i++){
    for(int j=0;j<N_STATES;j++){
      int d = (j>i)?(j-i):(i-j);
      prob_t cost = (d==0)?prob_t(0) : (d==1?prob_t(0.5):prob_t(2));
      transition[i*N_STATES+j] = cost;
    }
  }
  for(int s=0;s<N_STATES;s++){
    for(int k=0;k<N_TOKENS;k++){
      emission[s*N_TOKENS+k] = (k==s)?prob_t(0):prob_t(1);
    }
  }
}


static void ref_viterbi( const tok_t obs[N_OBS],
                         const prob_t init[N_STATES],
                         const prob_t transition[N_STATES*N_STATES],
                         const prob_t emission[N_STATES*N_TOKENS],
                         state_t path[N_OBS] )
{
  prob_t llike[N_OBS][N_STATES];
  for(state_t s=0;s<N_STATES;s++){
    llike[0][s] = init[s] + emission[s*N_TOKENS + obs[0]];
  }
  for(step_t t=1;t<N_OBS;t++){
    for(state_t curr=0; curr<N_STATES; curr++){
      prob_t min_p = llike[t-1][0] + transition[0*N_STATES+curr] + emission[curr*N_TOKENS+obs[t]];
      for(state_t prev=1; prev<N_STATES; prev++){
        prob_t p = llike[t-1][prev] + transition[prev*N_STATES+curr] + emission[curr*N_TOKENS+obs[t]];
        if(p < min_p) min_p = p;
      }
      llike[t][curr] = min_p;
    }
  }
  state_t min_s = 0;
  prob_t  min_p = llike[N_OBS-1][0];
  for(state_t s=1;s<N_STATES;s++){
    prob_t p = llike[N_OBS-1][s];
    if(p < min_p){ min_p = p; min_s = s; }
  }
  path[N_OBS-1] = min_s;
  for(step_t t=N_OBS-2; t>=0; --t){
    state_t best = 0;
    prob_t  bp   = llike[t][0] + transition[0*N_STATES + path[t+1]];
    for(state_t s=1;s<N_STATES;s++){
      prob_t p = llike[t][s] + transition[s*N_STATES + path[t+1]];
      if(p < bp){ bp = p; best = s; }
    }
    path[t] = best;
  }
}


static void make_obs_case(int id, tok_t obs[N_OBS], std::string& name){
  auto wrap = [](int v){ return (tok_t)( (v % N_TOKENS + N_TOKENS) % N_TOKENS ); };

  if(id==0){
    name = "RAMP_MODN";
    for(int t=0;t<N_OBS;t++) obs[t] = wrap(t);             
  }else if(id==1){
    name = "ALT_7_13_WRAPPED";
    const int a = wrap(7), b = wrap(13);                   
    for(int t=0;t<N_OBS;t++) obs[t] = (tok_t)((t&1)?b:a);
  }else if(id==2){
    name = "BLOCKS_WRAPPED";
    for(int t=0;t<N_OBS;t++){
      int b = (t/10)%6;
      obs[t] = wrap(b*9);                                  
    }
  }else if(id==3){
    name = "SAW_SMALL_WRAPPED";
    for(int t=0;t<N_OBS;t++) obs[t] = wrap(t % 16);        
  }else{
    name = "PATTERN_MIX_WRAPPED";
    for(int t=0;t<N_OBS;t++){
      int v = (t*5 + (t>>3));                              
      obs[t] = wrap(v);
    }
  }

#ifndef __SYNTHESIS__

  for(int t=0;t<N_OBS;t++){
    if(obs[t] >= N_TOKENS){
      fprintf(stderr, "[ERROR] make_obs_case produced obs[%d]=%u >= %d\n",
              t, (unsigned)obs[t], N_TOKENS);
      std::exit(2);
    }
  }
#endif
}

int main(){
  prob_t init[N_STATES];
  prob_t transition[N_STATES*N_STATES];
  prob_t emission[N_STATES*N_TOKENS];

  std::vector<std::string> local_results;
  bool global_pass = true;

  for(int tcase=0;tcase<5;tcase++){
    tok_t   obs[N_OBS];
    state_t path[N_OBS];
    state_t golden[N_OBS];
    std::string case_name;

    make_obs_case(tcase, obs, case_name);
    build_smooth_hmm(init, transition, emission);

    int rc = viterbi(obs, init, transition, emission, path);
    if (rc != 0) {
      std::printf("DUT returned error code %d on case %d (%s)\n", rc, tcase, case_name.c_str());
      global_pass = false;
      continue;
    }
    ref_viterbi(obs, init, transition, emission, golden);

    bool local_pass = true;
    for(int i=0;i<N_OBS;i++){
      if(path[i]!=golden[i]){ local_pass=false; break; }
    }
    if(!local_pass) global_pass=false;

    std::string input_str  = vec_u8_to_str(obs, N_OBS);
    std::string actual_str = vec_state_to_str(path, N_OBS);
    std::string golden_str = vec_state_to_str(golden, N_OBS);

    std::stringstream result_line;
    result_line << "LOCAL_CHECK" << (tcase + 1) << " [" << case_name << "]: "
                << (local_pass ? "PASS" : "FAIL")
                << ", Input: " << input_str
                << ", Actual Output: " << actual_str
                << ", Golden Output: " << golden_str;

    local_results.push_back(result_line.str());
    std::printf("%s\n", result_line.str().c_str());
  }

  std::ofstream outfile("result.txt");
  if (outfile.is_open()) {
    outfile << "GLOBAL_CHECK: " << (global_pass ? "PASS" : "FAIL") << std::endl;
    for (const auto& line : local_results) {
      outfile << line << std::endl;
    }
    outfile.close();
    std::printf("\nResults saved to result.txt\n");
  } else {
    std::printf("\nError: Could not open result.txt for writing.\n");
  }
  return global_pass ? 0 : 1;
}
