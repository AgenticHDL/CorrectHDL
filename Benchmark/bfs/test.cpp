#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <sstream>
#include <string>
#include <vector>
#include <fstream>
#include "mc_scverify.h"

#define SCALE 4
#define EDGE_FACTOR 4
#define N_NODES (1LL<<SCALE)
#define N_EDGES (N_NODES*EDGE_FACTOR)
#define N_LEVELS 10

typedef uint64_t edge_index_t;
typedef uint64_t node_index_t;

typedef struct edge_t_struct {
  node_index_t dst;
} edge_t;

typedef struct node_t_struct {
  edge_index_t edge_begin;
  edge_index_t edge_end;
} node_t;

typedef int8_t level_t;
#define MAX_LEVEL INT8_MAX

void bfs(node_t nodes[N_NODES], edge_t edges[N_EDGES], node_index_t starting_node, level_t level[N_NODES], edge_index_t level_counts[N_LEVELS]);

static inline void zero_graph(node_t* nodes, edge_t* edges) {
  std::memset(nodes, 0, sizeof(node_t)*N_NODES);
  std::memset(edges, 0, sizeof(edge_t)*N_EDGES);
}

static inline void init_state(level_t* level, edge_index_t* level_counts) {
  for (int i=0;i<N_NODES;i++) level[i]=MAX_LEVEL;
  for (int i=0;i<N_LEVELS;i++) level_counts[i]=0;
}

static inline std::string vec_to_str_dec(const edge_index_t* v) {
  std::ostringstream oss;
  oss << "[";
  for (int i=0;i<N_LEVELS;i++) {
    oss << (unsigned int)v[i];
    if (i!=N_LEVELS-1) oss << ",";
  }
  oss << "]";
  return oss.str();
}

static inline bool eq_counts(const edge_index_t* a, const edge_index_t* b) {
  for (int i=0;i<N_LEVELS;i++) if (a[i]!=b[i]) return false;
  return true;
}

int main() {
  node_t* nodes = (node_t*)std::malloc(sizeof(node_t)*N_NODES);
  edge_t* edges = (edge_t*)std::malloc(sizeof(edge_t)*N_EDGES);
  level_t level[N_NODES];
  edge_index_t level_counts[N_LEVELS];

  std::vector<std::string> local_results;
  bool global_pass = true;

  struct Meta { node_index_t start; edge_index_t golden[N_LEVELS]; };
  Meta metas[5];

  for (int i=0;i<5;i++) { metas[i].start=0; for (int j=0;j<N_LEVELS;j++) metas[i].golden[j]=0; }


  zero_graph(nodes, edges);
  edge_index_t ep=0;
  for (int i=0;i<7;i++) { nodes[i].edge_begin=ep; edges[ep].dst=(node_index_t)(i+1); ep++; nodes[i].edge_end=ep; }
  metas[0].start=0;
  { edge_index_t g[N_LEVELS]={1,1,1,1,1,1,1,1}; for (int k=0;k<N_LEVELS;k++) metas[0].golden[k]=g[k]; }


  zero_graph(nodes, edges);
  ep=0;
  nodes[5].edge_begin=ep;
  for (int d=6; d<=15; d++) { edges[ep].dst=(node_index_t)d; ep++; }
  nodes[5].edge_end=ep;
  metas[1].start=5;
  { edge_index_t g[N_LEVELS]={1,10,0,0,0,0,0,0}; for (int k=0;k<N_LEVELS;k++) metas[1].golden[k]=g[k]; }


  zero_graph(nodes, edges);
  ep=0;
  nodes[2].edge_begin=ep; edges[ep].dst=3; ep++; nodes[2].edge_end=ep;
  nodes[3].edge_begin=ep; edges[ep].dst=4; ep++; nodes[3].edge_end=ep;
  nodes[4].edge_begin=ep; edges[ep].dst=2; ep++; nodes[4].edge_end=ep;
  metas[2].start=3;
  { edge_index_t g[N_LEVELS]={1,1,1,0,0,0,0,0}; for (int k=0;k<N_LEVELS;k++) metas[2].golden[k]=g[k]; }


  zero_graph(nodes, edges);
  ep=0;
  nodes[1].edge_begin=ep; edges[ep].dst=2; ep++; edges[ep].dst=3; ep++; nodes[1].edge_end=ep;
  nodes[2].edge_begin=ep; edges[ep].dst=4; ep++; edges[ep].dst=5; ep++; nodes[2].edge_end=ep;
  nodes[3].edge_begin=ep; edges[ep].dst=6; ep++; edges[ep].dst=7; ep++; nodes[3].edge_end=ep;
  metas[3].start=1;
  { edge_index_t g[N_LEVELS]={1,2,4,0,0,0,0,0}; for (int k=0;k<N_LEVELS;k++) metas[3].golden[k]=g[k]; }


  zero_graph(nodes, edges);
  ep=0;
  nodes[8].edge_begin=ep; edges[ep].dst=8; ep++; edges[ep].dst=9; ep++; edges[ep].dst=9; ep++; nodes[8].edge_end=ep;
  nodes[9].edge_begin=ep; edges[ep].dst=10; ep++; nodes[9].edge_end=ep;
  metas[4].start=8;
  { edge_index_t g[N_LEVELS]={1,1,1,0,0,0,0,0}; for (int k=0;k<N_LEVELS;k++) metas[4].golden[k]=g[k]; }

  for (int i=0;i<5;i++) {
    zero_graph(nodes, edges);
    edge_index_t epX=0;
    if (i==0) {
      for (int k=0;k<7;k++){ nodes[k].edge_begin=epX; edges[epX].dst=(node_index_t)(k+1); epX++; nodes[k].edge_end=epX; }
    } else if (i==1) {
      nodes[5].edge_begin=epX; for (int d=6; d<=15; d++){ edges[epX].dst=(node_index_t)d; epX++; } nodes[5].edge_end=epX;
    } else if (i==2) {
      nodes[2].edge_begin=epX; edges[epX].dst=3; epX++; nodes[2].edge_end=epX;
      nodes[3].edge_begin=epX; edges[epX].dst=4; epX++; nodes[3].edge_end=epX;
      nodes[4].edge_begin=epX; edges[epX].dst=2; epX++; nodes[4].edge_end=epX;
    } else if (i==3) {
      nodes[1].edge_begin=epX; edges[epX].dst=2; epX++; edges[epX].dst=3; epX++; nodes[1].edge_end=epX;
      nodes[2].edge_begin=epX; edges[epX].dst=4; epX++; edges[epX].dst=5; epX++; nodes[2].edge_end=epX;
      nodes[3].edge_begin=epX; edges[epX].dst=6; epX++; edges[epX].dst=7; epX++; nodes[3].edge_end=epX;
    } else if (i==4) {
      nodes[8].edge_begin=epX; edges[epX].dst=8; epX++; edges[epX].dst=9; epX++; edges[epX].dst=9; epX++; nodes[8].edge_end=epX;
      nodes[9].edge_begin=epX; edges[epX].dst=10; epX++; nodes[9].edge_end=epX;
    }

    init_state(level, level_counts);
    bfs(nodes, edges, metas[i].start, level, level_counts);

    std::string actual_s = vec_to_str_dec(level_counts);
    std::string golden_s = vec_to_str_dec(metas[i].golden);
    bool local_pass = eq_counts(level_counts, metas[i].golden);
    global_pass = global_pass && local_pass;

    std::stringstream line;
    line << "LOCAL_CHECK" << (i+1) << ": " << (local_pass ? "PASS" : "FAIL")
         << ", Input: start=" << (unsigned int)metas[i].start
         << ", Actual Output: " << actual_s
         << ", Golden Output: " << golden_s;
    local_results.push_back(line.str());
    std::printf("%s\n", line.str().c_str());
  }

  std::ofstream outfile("result.txt");
  if (outfile.is_open()) {
    outfile << "GLOBAL_CHECK: " << (global_pass ? "PASS" : "FAIL") << std::endl;
    for (const auto& s : local_results) outfile << s << std::endl;
    outfile.close();
    std::printf("\nResults saved to result.txt\n");
  } else {
    std::printf("\nError: Could not open result.txt for writing.\n");
  }

  std::free(nodes);
  std::free(edges);
  CCS_RETURN(global_pass ? 0 : 1);
}
