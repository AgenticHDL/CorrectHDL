// test.cpp
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <iomanip>
#include <algorithm>
#include <cstdio>
#include <cmath>
#include <ac_fixed.h>

#ifndef W
#define W 8
#endif
#ifndef H
#define H 8
#endif

typedef ac_fixed<12,4,true,AC_RND,AC_SAT> DATA_TYPE;

extern void deriche_execute(int w, int h, DATA_TYPE alpha, const DATA_TYPE* in_flat, DATA_TYPE* out_flat);

std::string to_float_string(const float* data, size_t len) {
  std::stringstream ss;
  ss << std::fixed << std::setprecision(3);
  for (size_t i = 0; i < len; ++i) {
    ss << data[i];
    if (i + 1 < len) ss << " ";
  }
  return ss.str();
}

std::string to_fx_string(const DATA_TYPE* data, size_t len) {
  std::stringstream ss;
  ss << std::fixed << std::setprecision(3);
  for (size_t i = 0; i < len; ++i) {
    ss << data[i].to_double();
    if (i + 1 < len) ss << " ";
  }
  return ss.str();
}

void make_input1(int w,int h,std::vector<DATA_TYPE>& img) {
  img.resize(w*h);
  const double inv65535 = 1.0/65535.0;
  for (int i=0;i<w;i++) for (int j=0;j<h;j++) img[i*h+j] = DATA_TYPE(((313*i + 991*j) % 65536) * inv65535);
}
void make_input2(int w,int h,std::vector<DATA_TYPE>& img) {
  img.resize(w*h);
  double denom = double((w-1)+(h-1));
  double invd = 1.0/denom;
  for (int i=0;i<w;i++) for (int j=0;j<h;j++) img[i*h+j] = DATA_TYPE(double(i + j) * invd);
}
void make_input3(int w,int h,std::vector<DATA_TYPE>& img) {
  img.resize(w*h);
  for (int i=0;i<w;i++) for (int j=0;j<h;j++) img[i*h+j] = DATA_TYPE(((i + j) % 2)==0 ? 1.0 : 0.0);
}
void make_input4(int w,int h,std::vector<DATA_TYPE>& img) {
  img.assign(w*h, DATA_TYPE(0.0));
  img[(w/2)*h + (h/2)] = DATA_TYPE(1.0);
}
void make_input5(int w,int h,std::vector<DATA_TYPE>& img) {
  img.resize(w*h);
  unsigned int x = 12345u;
  const double inv65535 = 1.0/65535.0;
  for (int i=0;i<w;i++) for (int j=0;j<h;j++) { x = 1103515245u*x + 12345u; double v = double((x & 0x7fffffff) % 65536) * inv65535; img[i*h+j] = DATA_TYPE(v); }
}

int main(int argc, char *argv[]) {
  const int w = W;
  const int h = H;
  const DATA_TYPE alpha = DATA_TYPE(0.25);

  std::vector<std::vector<DATA_TYPE>> inputs(5);
  make_input1(w,h,inputs[0]);
  make_input2(w,h,inputs[1]);
  make_input3(w,h,inputs[2]);
  make_input4(w,h,inputs[3]);
  make_input5(w,h,inputs[4]);

  const std::vector<std::vector<float>> goldens = {
{
  0.00008506f, -0.00014652f, 0.00006863f, 0.00189596f, 0.00561168f, 0.00916552f, 0.00904250f, 0.00387769f,
  0.00001304f, -0.00022440f, 0.00002136f, 0.00189973f, 0.00567206f, 0.00926708f, 0.00914086f, 0.00391878f,
  0.00006007f, -0.00009263f, 0.00004789f, 0.00125252f, 0.00370456f, 0.00605048f, 0.00596938f, 0.00255990f,
  0.00062456f, 0.00053340f, 0.00041756f, 0.00109796f, 0.00285743f, 0.00464363f, 0.00459601f, 0.00197956f,
  0.00180968f, 0.00169501f, 0.00120186f, 0.00199038f, 0.00471792f, 0.00763581f, 0.00757728f, 0.00327525f,
  0.00295342f, 0.00277537f, 0.00196097f, 0.00317581f, 0.00748284f, 0.01210741f, 0.01201673f, 0.00519543f,
  0.00291523f, 0.00273377f, 0.00193592f, 0.00318037f, 0.00752251f, 0.01217376f, 0.01208121f, 0.00522251f,
  0.00125100f, 0.00116976f, 0.00083093f, 0.00139163f, 0.00330840f, 0.00535528f, 0.00531377f, 0.00229659f
},
{
  0.00061072f, -0.00047918f, 0.00046203f, 0.00904810f, 0.02664102f, 0.04350428f, 0.04292563f, 0.01841086f,
  -0.00047918f, -0.00161108f, -0.00025585f, 0.00873439f, 0.02644616f, 0.04322975f, 0.04262729f, 0.01826674f,
  0.00046203f, -0.00025585f, 0.00034381f, 0.00599519f, 0.01761299f, 0.02875934f, 0.02837829f, 0.01217235f,
  0.00904810f, 0.00873439f, 0.00599519f, 0.00788289f, 0.01740257f, 0.02807007f, 0.02791547f, 0.01210183f,
  0.02664102f, 0.02644616f, 0.01761299f, 0.01740256f, 0.03387254f, 0.05427259f, 0.05420490f, 0.02363387f,
  0.04350428f, 0.04322975f, 0.02875934f, 0.02807007f, 0.05427259f, 0.08692583f, 0.08683849f, 0.03787472f,
  0.04292563f, 0.04262730f, 0.02837829f, 0.02791547f, 0.05420489f, 0.08683850f, 0.08673773f, 0.03782291f,
  0.01841086f, 0.01826674f, 0.01217235f, 0.01210183f, 0.02363387f, 0.03787472f, 0.03782291f, 0.01648850f
},
{
  0.04333168f, 0.04186492f, 0.02629806f, 0.01857153f, 0.02844820f, 0.04352218f, 0.04181726f, 0.01602345f,
  0.04186492f, 0.04470434f, 0.02964702f, 0.01903635f, 0.02619268f, 0.04219016f, 0.04462828f, 0.02201502f,
  0.02629807f, 0.02964702f, 0.02018214f, 0.01236008f, 0.01597799f, 0.02655429f, 0.02958820f, 0.01623190f,
  0.01857153f, 0.01903635f, 0.01236008f, 0.00824047f, 0.01186057f, 0.01868944f, 0.01900821f, 0.00854600f,
  0.02844820f, 0.02619268f, 0.01597798f, 0.01186057f, 0.01906937f, 0.02853039f, 0.02617051f, 0.00853562f,
  0.04352218f, 0.04219016f, 0.02655429f, 0.01868944f, 0.02853039f, 0.04371819f, 0.04214129f, 0.01631063f,
  0.04181726f, 0.04462828f, 0.02958820f, 0.01900821f, 0.02617051f, 0.04214129f, 0.04455248f, 0.02195132f,
  0.01602345f, 0.02201502f, 0.01623190f, 0.00854600f, 0.00853562f, 0.01631063f, 0.02195132f, 0.01595514f
},
{
  0.00803864f, 0.00697177f, -0.00358779f, -0.01646862f, -0.01691691f, -0.00434419f, 0.00660761f, 0.00819120f,
  0.00697177f, 0.00604649f, -0.00311162f, -0.01428295f, -0.01467174f, -0.00376764f, 0.00573066f, 0.00710408f,
  -0.00358779f, -0.00311162f, 0.00160129f, 0.00735024f, 0.00755031f, 0.00193889f, -0.00294909f, -0.00365588f,
  -0.01646862f, -0.01428295f, 0.00735024f, 0.03373900f, 0.03465739f, 0.00889987f, -0.01353690f, -0.01678117f,
  -0.01691690f, -0.01467173f, 0.00755031f, 0.03465739f, 0.03560077f, 0.00914213f, -0.01390538f, -0.01723796f,
  -0.00434419f, -0.00376764f, 0.00193889f, 0.00889987f, 0.00914213f, 0.00234766f, -0.00357084f, -0.00442664f,
  0.00660761f, 0.00573066f, -0.00294909f, -0.01353690f, -0.01390537f, -0.00357084f, 0.00543133f, 0.00673301f,
  0.00819120f, 0.00710408f, -0.00365588f, -0.01678117f, -0.01723796f, -0.00442664f, 0.00673301f, 0.00834665f
},
{
  0.01923163f, 0.04246249f, 0.04043044f, 0.01428474f, -0.00443718f, 0.01316516f, 0.04459097f, 0.04170041f,
  0.03226313f, 0.08091320f, 0.07912447f, 0.03065615f, -0.01715407f, -0.01505271f, 0.02805200f, 0.04682120f,
  0.02574326f, 0.06222970f, 0.06354848f, 0.03492842f, 0.00384325f, -0.00353614f, 0.01359641f, 0.02313796f,
  0.01266925f, 0.00927749f, 0.01319701f, 0.03074310f, 0.05004256f, 0.04678801f, 0.01915336f, -0.00814362f,
  0.02027511f, -0.00435000f, -0.00763864f, 0.02544697f, 0.07091848f, 0.07648398f, 0.03015613f, -0.01927213f,
  0.04390716f, 0.03600398f, 0.02262845f, 0.02725608f, 0.04917099f, 0.05587609f, 0.02986740f, -0.00641507f,
  0.04434246f, 0.06560275f, 0.05676056f, 0.03147015f, 0.01283022f, 0.01199731f, 0.01787357f, 0.01142352f,
  0.01357068f, 0.04377065f, 0.04844039f, 0.02168228f, -0.01299591f, -0.02072393f, -0.00031680f, 0.01485866f
}
  };

  bool global_pass = true;
  std::vector<std::string> local_results;

  for (size_t i = 0; i < inputs.size(); ++i) {
    std::vector<DATA_TYPE> out(w*h, DATA_TYPE(0.0));
    int n_inst = 0;
    deriche_execute(w, h, alpha, inputs[i].data(), out.data());
    bool local_pass = true;
    for (int k = 0; k < w*h; ++k) {
      double diff = std::fabs(out[k].to_double() - double(goldens[i][k]));
      if (diff > 0.006) { local_pass = false; break; }
    }
    if (!local_pass) global_pass = false;

    std::string input_str = to_fx_string(inputs[i].data(), inputs[i].size());
    std::string actual_str = to_fx_string(out.data(), out.size());
    std::string golden_str = to_float_string(goldens[i].data(), goldens[i].size());

    std::stringstream result_line;
    result_line << "LOCAL_CHECK" << (i + 1) << ": "
                << (local_pass ? "PASS" : "FAIL")
                << ", Input: " << input_str
                << ", Actual Output: " << actual_str
                << ", Golden Output: " << golden_str
                << ", N_INST: " << n_inst;

    local_results.push_back(result_line.str());
    std::printf("%s\n", result_line.str().c_str());
  }

  std::ofstream outfile("results.txt");
  if (outfile.is_open()) {
    outfile << "GLOBAL_CHECK: " << (global_pass ? "PASS" : "FAIL") << std::endl;
    for (const auto& line : local_results) outfile << line << std::endl;
    outfile.close();
    std::printf("\nResults saved to results.txt\n");
  } else {
    std::printf("\nError: Could not open results.txt for writing.\n");
  }
  return global_pass ? 0 : 1;
}
