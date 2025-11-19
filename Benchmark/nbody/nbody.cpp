#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <ac_fixed.h>

typedef ac_fixed<16,8,true,AC_TRN,AC_WRAP> TYPE;

#define nAtoms        32
#define maxNeighbors  4

static const TYPE lj1 = TYPE(1.5);
static const TYPE lj2 = TYPE(2.0);

void md_kernel(TYPE force_x[nAtoms],
               TYPE force_y[nAtoms],
               TYPE force_z[nAtoms],
               TYPE position_x[nAtoms],
               TYPE position_y[nAtoms],
               TYPE position_z[nAtoms],
               int32_t NL[nAtoms*maxNeighbors]);

struct bench_args_t {
  TYPE force_x[nAtoms];
  TYPE force_y[nAtoms];
  TYPE force_z[nAtoms];
  TYPE position_x[nAtoms];
  TYPE position_y[nAtoms];
  TYPE position_z[nAtoms];
  int32_t NL[nAtoms*maxNeighbors];
};

#pragma hls_design top
#pragma design_goal area
void md_kernel(TYPE force_x[nAtoms],
               TYPE force_y[nAtoms],
               TYPE force_z[nAtoms],
               TYPE position_x[nAtoms],
               TYPE position_y[nAtoms],
               TYPE position_z[nAtoms],
               int32_t NL[nAtoms*maxNeighbors])
{
  TYPE delx, dely, delz;
  TYPE r2inv, r6inv, potential, force, j_x, j_y, j_z;
  TYPE i_x, i_y, i_z, fx, fy, fz;
  int32_t i, j, jidx;

  const TYPE INV_1   = TYPE(1.0);        // 1 / 1
  const TYPE INV_4   = TYPE(0.25);       // 1 / 4
  const TYPE INV_16  = TYPE(0.0625);     // 1 / 16
  const TYPE INV_64  = TYPE(0.015625);   // 1 / 64

loop_i:
  for (i = 0; i < nAtoms; i++){
    i_x = position_x[i];
    i_y = position_y[i];
    i_z = position_z[i];
    fx = TYPE(0);
    fy = TYPE(0);
    fz = TYPE(0);
loop_j:
    for (j = 0; j < maxNeighbors; j++){
      jidx = NL[i*maxNeighbors + j];


      int dx = i - jidx;            
      if (dx >  nAtoms/2) dx -= nAtoms;
      if (dx < -nAtoms/2) dx += nAtoms;


      delx = TYPE(dx);
      dely = TYPE(0);
      delz = TYPE(0);


      int adx = dx < 0 ? -dx : dx;
      if      (adx == 1)  r2inv = INV_1;
      else if (adx == 2)  r2inv = INV_4;
      else if (adx == 4)  r2inv = INV_16;
      else if (adx == 8)  r2inv = INV_64;
      else                 r2inv = TYPE(0);


      r6inv = r2inv * r2inv * r2inv;
      potential = r6inv * ((lj1 * r6inv) - lj2);
      force = r2inv * potential;

      fx += delx * force;
      fy += dely * force;
      fz += delz * force;
    }
    force_x[i] = fx;
    force_y[i] = fy;
    force_z[i] = fz;
  }
}
