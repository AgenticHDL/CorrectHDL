// test.cpp
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <vector>
#include <fstream>
#include <string>
#include "gemm.h"


static inline void zero(TYPE* a){ for(int i=0;i<N;i++) a[i] = TYPE(0); }


static inline uint32_t sum_prod_uint(const TYPE* prod){
  uint32_t acc = 0u;
  for(int i=0;i<N;i++){
    int v = prod[i].to_int();   
    if(v >= 0) acc += (uint32_t)v;
    else       acc -= (uint32_t)(-v); 
  }
  return acc;
}


static inline void case_all_ones(TYPE* m1, TYPE* m2){
  for(int i=0;i<N;i++){ m1[i]=TYPE(1); m2[i]=TYPE(1); }
}
static inline void case_identity(TYPE* m){
  for(int i=0;i<row_size;i++)
    for(int k=0;k<col_size;k++)
      m[i*col_size+k] = (i==k)? TYPE(1) : TYPE(0);
}
static inline void case_m2_col_inc(TYPE* m2){
  for(int k=0;k<row_size;k++)
    for(int j=0;j<col_size;j++)
      m2[k*col_size+j] = TYPE(j+1); 
}
static inline void case_m1_row_inc(TYPE* m1){
  for(int i=0;i<row_size;i++)
    for(int k=0;k<col_size;k++)
      m1[i*col_size+k] = TYPE(i+1); 
}

int main(){
  TYPE* m1  = (TYPE*)std::malloc(sizeof(TYPE)*N);
  TYPE* m2  = (TYPE*)std::malloc(sizeof(TYPE)*N);
  TYPE* prod= (TYPE*)std::malloc(sizeof(TYPE)*N);

  struct TV { int id; uint32_t golden; };
  std::vector<TV> tv;
  tv.push_back({1, 4096u});      // ones x ones: 4096*64
  tv.push_back({2, 256u});        // I x ones
  tv.push_back({3, 2176u});      // I x col_inc
  tv.push_back({4, 34816u});     // row_inc x ones: 4096*2080
  tv.push_back({5, 295936u});   // row_inc x col_inc: 64*2080*2080

  std::vector<std::string> lines;
  bool global_pass = true;

  for(int t=0;t<5;t++){
    zero(m1); zero(m2); zero(prod);

    if(t==0){
      case_all_ones(m1,m2);
    }else if(t==1){
      case_identity(m1);
      for(int i=0;i<N;i++) m2[i]=TYPE(1);
    }else if(t==2){
      case_identity(m1);
      case_m2_col_inc(m2);
    }else if(t==3){
      case_m1_row_inc(m1);
      for(int i=0;i<N;i++) m2[i]=TYPE(1);
    }else{
      case_m1_row_inc(m1);
      case_m2_col_inc(m2);
    }

    gemm(m1,m2,prod);
    uint32_t actual = sum_prod_uint(prod);
    uint32_t golden = tv[t].golden;
    bool pass = (actual==golden);
    global_pass = global_pass && pass;

    char buf[160];
    std::snprintf(buf, sizeof(buf),
                  "LOCAL_CHECK%d: %s, Input: %d, Actual Output: %u, Golden Output: %u",
                  t+1, pass?"PASS":"FAIL", tv[t].id, actual, golden);
    lines.push_back(buf);
    std::printf("%s\n", buf);
  }

  std::printf("\nGLOBAL_CHECK: %s\n", global_pass?"PASS":"FAIL");


  std::ofstream ofs("result.txt");
  if(ofs.is_open()){
    ofs << "GLOBAL_CHECK: " << (global_pass?"PASS":"FAIL") << "\n";
    for(auto& s: lines) ofs << s << "\n";
    ofs.close();
    std::printf("Results saved to result.txt\n");
  }else{
    std::printf("Error: Could not open result.txt for writing.\n");
  }

  std::free(m1); std::free(m2); std::free(prod);
  return global_pass?0:1;
}
