#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <string>
#include <sstream>
#include <vector>
#include <fstream>
#include <ac_fixed.h>

typedef ac_fixed<16,8,true,AC_TRN,AC_WRAP> TYPE;

#define nAtoms        32
#define maxNeighbors  4

void md_kernel(TYPE force_x[nAtoms],
               TYPE force_y[nAtoms],
               TYPE force_z[nAtoms],
               TYPE position_x[nAtoms],
               TYPE position_y[nAtoms],
               TYPE position_z[nAtoms],
               int32_t NL[nAtoms*maxNeighbors]);

static inline int wrap(int idx){
  int m = nAtoms;
  int v = idx % m;
  if(v < 0) v += m;
  return v;
}

static inline void zeros(TYPE* a, int n){
  for(int i=0;i<n;i++) a[i]=TYPE(0);
}

static inline void set_positions_linear(TYPE* px, TYPE* py, TYPE* pz){
  for(int i=0;i<nAtoms;i++){
    px[i]=TYPE(i);
    py[i]=TYPE(0);
    pz[i]=TYPE(0);
  }
}

static inline void build_neighbors_offsets(int32_t* NL, const std::vector<int>& offs){
  for(int i=0;i<nAtoms;i++){
    int w=0;
    for(size_t k=0;k<offs.size() && w<maxNeighbors;k++){
      NL[i*maxNeighbors + w] = wrap(i + offs[k]); w++;
    }
    while(w<maxNeighbors){
      NL[i*maxNeighbors + w] = wrap(i + offs[0]); w++;
    }
  }
}

static inline unsigned long long any_nonzero_forces(const TYPE* fx,const TYPE* fy,const TYPE* fz){
  for(int i=0;i<nAtoms;i++){
    if(!(fx[i] == TYPE(0))) return 1ULL;
    if(!(fy[i] == TYPE(0))) return 1ULL;
    if(!(fz[i] == TYPE(0))) return 1ULL;
  }
  return 0ULL;
}


static inline int wrap_min_image(int d){
  if (d >  nAtoms/2) d -= nAtoms;
  if (d <= -nAtoms/2) d += nAtoms;
  return d;
}


static inline unsigned int imbalance_mask(const int32_t* NL){
  unsigned int mask = 0;
  for(int i=0;i<nAtoms;i++){
    int c1=0, c2=0, c4=0, c8=0; 
    for(int j=0;j<maxNeighbors;j++){
      int d = wrap_min_image(NL[i*maxNeighbors + j] - i);
      int ad = d<0 ? -d : d;
      if      (ad==1) c1 += (d>0 ? +1 : -1);
      else if (ad==2) c2 += (d>0 ? +1 : -1);
      else if (ad==4) c4 += (d>0 ? +1 : -1);
      else if (ad==8) c8 += (d>0 ? +1 : -1);
    }
    if (c1!=0) mask |= 1u;
    if (c2!=0) mask |= 2u;
    if (c4!=0) mask |= 4u;
    if (c8!=0) mask |= 8u;
  }
  return mask;
}

int main(){
  TYPE* fx = (TYPE*)std::malloc(sizeof(TYPE)*nAtoms);
  TYPE* fy = (TYPE*)std::malloc(sizeof(TYPE)*nAtoms);
  TYPE* fz = (TYPE*)std::malloc(sizeof(TYPE)*nAtoms);
  TYPE* px = (TYPE*)std::malloc(sizeof(TYPE)*nAtoms);
  TYPE* py = (TYPE*)std::malloc(sizeof(TYPE)*nAtoms);
  TYPE* pz = (TYPE*)std::malloc(sizeof(TYPE)*nAtoms);
  int32_t* NL = (int32_t*)std::malloc(sizeof(int32_t)*nAtoms*maxNeighbors);

  std::vector<std::string> local_results;
  bool global_pass = true;

  struct TV { const char* name; std::vector<int> offsets; unsigned int golden_mask; };
  std::vector<TV> tests;

  tests.push_back({"BALANCED_[+1,-1,+2,-2]",
    {+1,-1,+2,-2}, 0u});

  tests.push_back({"IMBALANCE_ONLY_1_[+1,+1,+2,-2]",
    {+1,+1,+2,-2}, 1u});

  tests.push_back({"IMBALANCE_ONLY_2_[+1,-1,+2,+2]",
    {+1,-1,+2,+2}, 2u});

  tests.push_back({"IMBALANCE_1_AND_2_[+1,+1,+2,+2]",
    {+1,+1,+2,+2}, 3u});

  tests.push_back({"IMBALANCE_ONLY_8_[+8,+8,+8,+8]",
    {+8,+8,+8,+8}, 8u});

  tests.push_back({"IMBALANCE_2_AND_8_[+2,+2,+8,+8]",
    {+2,+2,+8,+8}, 10u});

  for(size_t t=0;t<tests.size();t++){
    set_positions_linear(px,py,pz);
    zeros(fx,nAtoms); zeros(fy,nAtoms); zeros(fz,nAtoms);
    build_neighbors_offsets(NL, tests[t].offsets);
    md_kernel(fx,fy,fz,px,py,pz,NL);

    unsigned int actual_mask = imbalance_mask(NL);
    unsigned long long anynz = any_nonzero_forces(fx,fy,fz);

    bool pass = (actual_mask == tests[t].golden_mask);
    if(!pass) global_pass = false;

    std::stringstream result_line;
    result_line << "LOCAL_CHECK" << (t + 1) << ": " << (pass ? "PASS" : "FAIL")
                << ", Input: " << tests[t].name
                << ", ActualMask: " << actual_mask
                << ", GoldenMask: " << tests[t].golden_mask
                << ", AnyNonZeroForces: " << anynz;

    local_results.push_back(result_line.str());
    std::printf("%s\n", result_line.str().c_str());
  }

  std::ofstream outfile("result.txt");
  if (outfile.is_open()) {
    outfile << "GLOBAL_CHECK: " << (global_pass ? "PASS" : "FAIL") << std::endl;
    for (const auto& line : local_results) outfile << line << std::endl;
    outfile.close();
    std::printf("\nResults saved to result.txt\n");
  } else {
    std::printf("\nError: Could not open result.txt for writing.\n");
  }

  std::free(fx); std::free(fy); std::free(fz);
  std::free(px); std::free(py); std::free(pz);
  std::free(NL);
  return global_pass ? 0 : 1;
}
