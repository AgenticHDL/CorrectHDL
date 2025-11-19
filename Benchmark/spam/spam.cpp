#include <ac_int.h>

#define NUM_FEATURES 10
#define NUM_TRAINING 20
#define NUM_EPOCHS   2
#define STEP_SIZE    1   


typedef ac_int<16, true> FeatureType; // Q6.10
typedef ac_int<16, true> DataType;    // Q6.10
typedef ac_int<8,  false> LabelType;  // 0/1


typedef ac_int<32, true> ProdType;


static inline FeatureType q6_10_mul(FeatureType a, FeatureType b) {
  ProdType prod = (ProdType)a * (ProdType)b;   // Q12.20
  return (FeatureType)(prod >> 10);            
}

// Hard-Sigmoid: y = clamp(0,1, 0.5 + x/4) => Q6.10: y = clamp(0,1024, 512 + (x>>>2))
static inline FeatureType SigmoidApprox(FeatureType x) {
  FeatureType y = (x >> 2) + FeatureType(512);  // 0.5 -> 512 in Q6.10
  if (y < FeatureType(0))    y = FeatureType(0);
  if (y > FeatureType(1024)) y = FeatureType(1024);
  return y;
}


static FeatureType dotProduct(FeatureType param[NUM_FEATURES], DataType feature[NUM_FEATURES]) {
  FeatureType acc = FeatureType(0); // Q6.10
  DOT_LOOP:
  for (int i = 0; i < NUM_FEATURES; i++) {
    acc += q6_10_mul(param[i], feature[i]);    
  }
  return acc; // Q6.10
}


static void computeGradient(FeatureType grad[NUM_FEATURES],
                            DataType feature[NUM_FEATURES],
                            FeatureType scale) {
  GRAD_LOOP:
  for (int i = 0; i < NUM_FEATURES; i++) {
    grad[i] = q6_10_mul(scale, feature[i]);
  }
}


static void updateParameter(FeatureType param[NUM_FEATURES],
                            FeatureType grad[NUM_FEATURES],
                            FeatureType scale) {
  UPD_LOOP:
  for (int i = 0; i < NUM_FEATURES; i++) {
    param[i] = (FeatureType)(param[i] + q6_10_mul(scale, grad[i]));
  }
}

#pragma hls_design top
void SgdLR_sw(DataType  data [NUM_FEATURES * NUM_TRAINING],
              LabelType label[NUM_TRAINING],
              FeatureType theta[NUM_FEATURES]) {
  FeatureType gradient[NUM_FEATURES];


  INIT_LOOP:
  for (int k = 0; k < NUM_FEATURES; k++) {
    theta[k] = FeatureType(0);
  }


  EPOCH_LOOP:
  for (int epoch = 0; epoch < NUM_EPOCHS; epoch++) {
    SAMPLE_LOOP:
    for (int training_id = 0; training_id < NUM_TRAINING; training_id++) {

      DataType* x = &data[NUM_FEATURES * training_id];


      FeatureType dot  = dotProduct(theta, x);


      FeatureType prob = SigmoidApprox(dot);


      FeatureType label_q = FeatureType((ac_int<16,true>)label[training_id] << 10);
      FeatureType e = (FeatureType)(prob - label_q);  // Q6.10


      computeGradient(gradient, x, e);


      updateParameter(theta, gradient, FeatureType(-1024));
    }
  }
}

void SgdLR_sw_int(DataType  data [NUM_FEATURES * NUM_TRAINING],
                  LabelType label[NUM_TRAINING],
                  ac_int<16,true> theta_int_out[NUM_FEATURES]) {
  FeatureType theta[NUM_FEATURES];
  SgdLR_sw(data, label, theta);
  CONV_LOOP:
  for (int i = 0; i < NUM_FEATURES; i++) {
    theta_int_out[i] = theta[i]; 
  }
}
