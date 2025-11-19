#include <ac_int.h>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <iostream>

#define NUM_FEATURES 10
#define NUM_TRAINING 20
#define NUM_EPOCHS   2
#define STEP_SIZE    1


typedef ac_int<16, true> FeatureType; // Q6.10
typedef ac_int<16, true> DataType;    // Q6.10
typedef ac_int<8,  false> LabelType;  // 0/1


extern void SgdLR_sw(DataType data[NUM_FEATURES * NUM_TRAINING],
                     LabelType label[NUM_TRAINING],
                     FeatureType theta[NUM_FEATURES]);
extern void SgdLR_sw_int(DataType  data [NUM_FEATURES * NUM_TRAINING],
                         LabelType label[NUM_TRAINING],
                         ac_int<16,true> theta_int_out[NUM_FEATURES]);

static inline uint64_t fnv1a64_update(uint64_t h, uint32_t v){ h ^= (uint64_t)v; h *= 1099511628211ULL; return h; }
static std::string digest_to_hex(uint64_t h){ static const char* d="0123456789abcdef"; std::string s(16,'0'); for(int i=0;i<16;i++){ int sh=(15-i)*4; s[i]=d[(h>>sh)&0xF]; } return s; }
static std::string digest_theta(const FeatureType* th){ uint64_t h=1469598103934665603ULL; for(int i=0;i<NUM_FEATURES;i++) h=fnv1a64_update(h,(uint32_t)((int)th[i])); return digest_to_hex(h); }
static std::string digest_theta_int(const ac_int<16,true>* th){ uint64_t h=1469598103934665603ULL; for(int i=0;i<NUM_FEATURES;i++) h=fnv1a64_update(h,(uint32_t)((int)th[i])); return digest_to_hex(h); }
static std::string digest_input(const DataType* data, const LabelType* lab){ uint64_t h=1469598103934665603ULL; for(int i=0;i<NUM_FEATURES*NUM_TRAINING;i++) h=fnv1a64_update(h,(uint32_t)((int)data[i])); for(int i=0;i<NUM_TRAINING;i++) h=fnv1a64_update(h,(uint32_t)((int)lab[i])); return digest_to_hex(h); }


static void make_case(int t, std::vector<DataType>& data, std::vector<LabelType>& label){
  int n, j;
  data.assign(NUM_FEATURES*NUM_TRAINING, DataType(0));
  label.assign(NUM_TRAINING, LabelType(0));
  if(t==0){
    for(n=0;n<NUM_TRAINING;n++){ for(j=0;j<NUM_FEATURES;j++) data[n*NUM_FEATURES+j]=DataType(0); label[n]=LabelType(0); }
  }else if(t==1){
    for(n=0;n<NUM_TRAINING;n++){ for(j=0;j<NUM_FEATURES;j++) data[n*NUM_FEATURES+j]=DataType((j%8)-3); label[n]=LabelType(n%2); }
  }else if(t==2){
    for(n=0;n<NUM_TRAINING;n++){ for(j=0;j<NUM_FEATURES;j++) data[n*NUM_FEATURES+j]=DataType(((n+j)&3)-1); label[n]=LabelType((n+j)&1); }
  }else if(t==3){
    unsigned int s=1234567u;
    for(n=0;n<NUM_TRAINING;n++){
      for(j=0;j<NUM_FEATURES;j++){ s=1664525u*s+1013904223u; int v=int((s>>28)&0xF)-8; data[n*NUM_FEATURES+j]=DataType(v); }
      label[n]=LabelType((s>>1)&1);
    }
  }else{
    for(n=0;n<NUM_TRAINING;n++){ for(j=0;j<NUM_FEATURES;j++) data[n*NUM_FEATURES+j]=DataType((n%5)-(j%3)); label[n]=LabelType((n%3)==0); }
  }
}


static std::string theta_to_decimal_str(const FeatureType* th){
  std::ostringstream oss;
  oss << "[";
  for(int i=0;i<NUM_FEATURES;i++){
    if(i) oss << ", ";
    oss << (int)th[i];
  }
  oss << "]";
  return oss.str();
}


static std::string theta_int_to_decimal_str(const ac_int<16,true>* th){
  std::ostringstream oss;
  oss << "[";
  for(int i=0;i<NUM_FEATURES;i++){
    if(i) oss << ", ";
    oss << (int)th[i];
  }
  oss << "]";
  return oss.str();
}

int main(){
  bool global_pass=true;
  std::vector<std::string> local_results;

  for(int t=0;t<5;t++){
    std::vector<DataType> data, data_g;
    std::vector<LabelType> label, label_g;
    make_case(t,data,label);
    data_g=data; label_g=label;


    bool used_int_api = false;
    FeatureType theta_act[NUM_FEATURES]; FeatureType theta_gld[NUM_FEATURES];
    ac_int<16,true> theta_act_i[NUM_FEATURES]; ac_int<16,true> theta_gld_i[NUM_FEATURES];


    for(int i=0;i<NUM_FEATURES;i++){
      theta_act[i]=FeatureType(0); theta_gld[i]=FeatureType(0);
      theta_act_i[i]=0; theta_gld_i[i]=0;
    }


    #ifdef USE_INT_API
      SgdLR_sw_int(data.data(), label.data(), theta_act_i);
      SgdLR_sw_int(data_g.data(), label_g.data(), theta_gld_i);
      used_int_api = true;
    #else
      SgdLR_sw(data.data(), label.data(), theta_act);
      SgdLR_sw(data_g.data(), label_g.data(), theta_gld);

      for(int i=0;i<NUM_FEATURES;i++){ theta_act_i[i] = theta_act[i]; theta_gld_i[i] = theta_gld[i]; }
    #endif

    bool local_pass=true;
    for(int i=0;i<NUM_FEATURES;i++){
      if(theta_act_i[i] != theta_gld_i[i]){ local_pass=false; break; }
    }
    if(!local_pass) global_pass=false;

    std::string input_str  = digest_input(data.data(), label.data());
    std::string actual_str = used_int_api ? digest_theta_int(theta_act_i) : digest_theta(theta_act);
    std::string golden_str = used_int_api ? digest_theta_int(theta_gld_i) : digest_theta(theta_gld);

    std::stringstream result_line;
    result_line << "LOCAL_CHECK" << (t + 1) << ": " << (local_pass ? "PASS" : "FAIL")
                << ", Input: " << input_str
                << ", Actual Output: " << actual_str
                << ", Golden Output: " << golden_str;

    std::string theta_dec_act = used_int_api ? theta_int_to_decimal_str(theta_act_i)
                                             : theta_to_decimal_str(theta_act);
    std::string theta_dec_gld = used_int_api ? theta_int_to_decimal_str(theta_gld_i)
                                             : theta_to_decimal_str(theta_gld);

    local_results.push_back(result_line.str());
    std::printf("%s\n", result_line.str().c_str());
    std::printf("THETA_DECIMAL%u_ACT: %s\n", (unsigned)(t+1), theta_dec_act.c_str());
    std::printf("THETA_DECIMAL%u_GLD: %s\n", (unsigned)(t+1), theta_dec_gld.c_str());
  }

  std::ofstream outfile("result.txt");
  if (outfile.is_open()) {
    outfile << "GLOBAL_CHECK: " << (global_pass ? "PASS" : "FAIL") << std::endl;
    for (int i=0;i<(int)local_results.size();++i) outfile << local_results[i] << std::endl;
    outfile.close();
    std::printf("Results saved to result.txt\n");
  } else {
    std::printf("Error: Could not open result.txt for writing.\n");
  }
  return global_pass ? 0 : 1;
}
