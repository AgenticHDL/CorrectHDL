#include <stdlib.h>
#include <inttypes.h>
#include <stdio.h>
#include <string.h>

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

struct bench_args_t {
  node_t nodes[N_NODES];
  edge_t edges[N_EDGES];
  node_index_t starting_node;
  level_t level[N_NODES];
  edge_index_t level_counts[N_LEVELS];
};

#pragma hls_design top
void bfs(node_t nodes[N_NODES], edge_t edges[N_EDGES],
            node_index_t starting_node, level_t level[N_NODES],
            edge_index_t level_counts[N_LEVELS])
{
  node_index_t n;
  edge_index_t e;
  level_t horizon;
  edge_index_t cnt;
  level[starting_node] = 0;
  level_counts[0] = 1;
  loop_horizons: for( horizon=0; horizon<(N_LEVELS-1); horizon++ ) {
    cnt = 0;
    loop_nodes: for( n=0; n<N_NODES; n++ ) {
      if( level[n]==horizon ) {
        edge_index_t tmp_begin = nodes[n].edge_begin;
        edge_index_t tmp_end = nodes[n].edge_end;
        loop_neighbors: for( e=tmp_begin; e<tmp_end; e++ ) {
          node_index_t tmp_dst = edges[e].dst;
          level_t tmp_level = level[tmp_dst];
          if( tmp_level == MAX_LEVEL ) {
            level[tmp_dst] = horizon+1;
            ++cnt;
          }
        }
      }
    }
    level_counts[horizon+1] = cnt;
    if( cnt==0 )
      break;
  }
}
