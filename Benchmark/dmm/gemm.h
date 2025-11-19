// gemm.h
#ifndef GEMM_H
#define GEMM_H

#include <ac_fixed.h>

#define row_size 16
#define col_size 16
#define N (row_size*col_size)


typedef ac_fixed<21, 21, true> TYPE;


void gemm(TYPE m1[N], TYPE m2[N], TYPE prod[N]);

#endif // GEMM_H
