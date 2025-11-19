// edge.cpp
#include <stdint.h>
#include <stdio.h>
#include <ac_fixed.h>

#ifndef W
#define W 8
#endif
#ifndef H
#define H 8
#endif

typedef ac_fixed<12,4,true,AC_RND,AC_SAT> DATA_TYPE;

static inline DATA_TYPE SV(double x){ return DATA_TYPE(x); }

static inline DATA_TYPE exp_poly(DATA_TYPE x)
{
  DATA_TYPE c1 = SV(1.0);
  DATA_TYPE c2 = SV(1.0);
  DATA_TYPE c3 = SV(0.5);
  DATA_TYPE c4 = SV(1.0/6.0);
  DATA_TYPE c5 = SV(1.0/24.0);
  DATA_TYPE c6 = SV(1.0/120.0);
  DATA_TYPE x2 = x*x;
  DATA_TYPE x3 = x2*x;
  DATA_TYPE x4 = x3*x;
  DATA_TYPE x5 = x4*x;
  return c1 + c2*x + c3*x2 + c4*x3 + c5*x4 + c6*x5;
}

static inline DATA_TYPE recip_nr(DATA_TYPE d)
{
  DATA_TYPE x = SV(1.0);
  x = x * (SV(2.0) - d * x);
  x = x * (SV(2.0) - d * x);
  return x;
}

#pragma hls_design top
void kernel_deriche(DATA_TYPE alpha, const DATA_TYPE imgIn[W*H], DATA_TYPE imgOut[W*H])
{
  int i,j;
  DATA_TYPE xm1, tm1, ym1, ym2;
  DATA_TYPE xp1, xp2;
  DATA_TYPE tp1, tp2;
  DATA_TYPE yp1, yp2;
  DATA_TYPE k;
  DATA_TYPE a1, a2, a3, a4, a5, a6, a7, a8;
  DATA_TYPE b1, b2, c1, c2;

  DATA_TYPE e_a = exp_poly(DATA_TYPE(0) - alpha);
  DATA_TYPE e_2a = exp_poly(DATA_TYPE(0) - SV(2.0)*alpha);
  DATA_TYPE ln2 = SV(0.69314718055994530942);
  DATA_TYPE two_neg_a = exp_poly((DATA_TYPE(0) - alpha)*ln2);

  DATA_TYPE num = (SV(1.0)-e_a)*(SV(1.0)-e_a);
  DATA_TYPE den = SV(1.0)+SV(2.0)*alpha*e_a - e_2a;
  k = num * recip_nr(den);

  a1 = k;
  a2 = k*e_a*(alpha - SV(1.0));
  a3 = k*e_a*(alpha + SV(1.0));
  a4 = DATA_TYPE(0) - k*e_2a;
  a5 = a1;
  a6 = a2;
  a7 = a3;
  a8 = a4;

  b1 = two_neg_a;
  b2 = DATA_TYPE(0) - e_2a;
  c1 = SV(1.0);
  c2 = SV(1.0);

  static DATA_TYPE y1[W*H];
  static DATA_TYPE y2[W*H];
  static DATA_TYPE tmp[W*H];

  for (i=0; i<W; i++) {
    ym1 = DATA_TYPE(0);
    ym2 = DATA_TYPE(0);
    xm1 = DATA_TYPE(0);
    for (j=0; j<H; j++) {
      int idx=i*H+j;
      DATA_TYPE v = a1*imgIn[idx] + a2*xm1 + b1*ym1 + b2*ym2;
      y1[idx]=v;
      xm1=imgIn[idx];
      ym2=ym1;
      ym1=v;
    }
  }

  for (i=0; i<W; i++) {
    yp1 = DATA_TYPE(0);
    yp2 = DATA_TYPE(0);
    xp1 = DATA_TYPE(0);
    xp2 = DATA_TYPE(0);
    for (j=H-1; j>=0; j--) {
      int idx=i*H+j;
      DATA_TYPE v = a3*xp1 + a4*xp2 + b1*yp1 + b2*yp2;
      y2[idx]=v;
      xp2=xp1;
      xp1=imgIn[idx];
      yp2=yp1;
      yp1=v;
    }
  }

  for (i=0; i<W; i++)
    for (j=0; j<H; j++) {
      int idx=i*H+j;
      tmp[idx] = c1*(y1[idx]+y2[idx]);
    }

  for (j=0; j<H; j++) {
    tm1 = DATA_TYPE(0);
    ym1 = DATA_TYPE(0);
    ym2 = DATA_TYPE(0);
    for (i=0; i<W; i++) {
      int idx=i*H+j;
      DATA_TYPE v = a5*tmp[idx] + a6*tm1 + b1*ym1 + b2*ym2;
      y1[idx]=v;
      tm1=tmp[idx];
      ym2=ym1;
      ym1=v;
    }
  }

  for (j=0; j<H; j++) {
    tp1 = DATA_TYPE(0);
    tp2 = DATA_TYPE(0);
    yp1 = DATA_TYPE(0);
    yp2 = DATA_TYPE(0);
    for (i=W-1; i>=0; i--) {
      int idx=i*H+j;
      DATA_TYPE v = a7*tp1 + a8*tp2 + b1*yp1 + b2*yp2;
      y2[idx]=v;
      tp2=tp1;
      tp1=tmp[idx];
      yp2=yp1;
      yp1=v;
    }
  }

  for (i=0; i<W; i++)
    for (j=0; j<H; j++) {
      int idx=i*H+j;
      imgOut[idx] = c2*(y1[idx]+y2[idx]);
    }
}

void deriche_execute(int w, int h, DATA_TYPE alpha, const DATA_TYPE* in_flat, DATA_TYPE* out_flat)
{
  kernel_deriche(alpha,in_flat,out_flat);
}
