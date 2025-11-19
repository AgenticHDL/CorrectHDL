// gemm.cpp
#include "gemm.h"
#include <ac_fixed.h>


typedef ac_fixed<14,14,true,AC_TRN,AC_WRAP> mul_t;           
typedef ac_fixed<32,32,true,AC_TRN,AC_SAT> acc_t;            

#pragma hls_design top
void gemm(TYPE m1[N], TYPE m2[N], TYPE prod[N]) {

  ROW_LOOP:
  for (int i = 0; i < row_size; ++i) {
    int i_col_base = i * col_size;


    COL_LOOP:
    for (int j = 0; j < col_size; ++j) {
      acc_t sum = 0;


      DOT_LOOP:
      for (int k = 0; k < row_size; ++k) {
        int k_col_base = k * col_size;


        mul_t a = (mul_t)m1[i_col_base + k];
        mul_t b = (mul_t)m2[k_col_base + j];
        mul_t term = a * b;

        sum += (acc_t)term;
      }


      prod[i_col_base + j] = (TYPE)sum;
    }
  }
}
