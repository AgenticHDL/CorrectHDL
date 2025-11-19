#include <cstdio>
#include <cstring>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <iomanip>

typedef signed char BYTE;


extern void sha_process(const BYTE in[], int len, signed int out[5]);

static inline signed int ROL32(signed int x, int n) { return (x << n) | (x >> (32 - n)); }
static inline signed int F1(signed int x,signed int y,signed int z){return (x & y) | (~x & z);}
static inline signed int F2(signed int x,signed int y,signed int z){return x ^ y ^ z;}
static inline signed int F3(signed int x,signed int y,signed int z){return (x & y) | (x & z) | (y & z);}
static inline signed int F4(signed int x,signed int y,signed int z){return x ^ y ^ z;}
static void ref_sha0(const BYTE* msg, int len, signed int out[5]) {
  signed int h0=0x67452301U,h1=0xefcdab89U,h2=0x98badcfeU,h3=0x10325476U,h4=0xc3d2e1f0U;
  int off=0;
  signed long long bitlen=(signed long long)len*8ULL;
  while (len - off >= 64) {
    signed int W[80];
    for (int i=0;i<16;++i) {
      const signed char* p=msg+off+4*i;
      W[i]=((signed int)p[0]<<24)|((signed int)p[1]<<16)|((signed int)p[2]<<8)|((signed int)p[3]);
    }
    for (int i=16;i<80;++i) W[i]=W[i-3]^W[i-8]^W[i-14]^W[i-16];
    signed int A=h0,B=h1,C=h2,D=h3,E=h4,temp;
    for (int i=0;i<20;++i){temp=ROL32(A,5)+F1(B,C,D)+E+W[i]+0x5a827999U;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    for (int i=20;i<40;++i){temp=ROL32(A,5)+F2(B,C,D)+E+W[i]+0x6ed9eba1U;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    for (int i=40;i<60;++i){temp=ROL32(A,5)+F3(B,C,D)+E+W[i]+0x8f1bbcdcU;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    for (int i=60;i<80;++i){temp=ROL32(A,5)+F4(B,C,D)+E+W[i]+0xca62c1d6U;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    h0+=A;h1+=B;h2+=C;h3+=D;h4+=E;
    off+=64;
  }
  signed char block[64];
  int rem=len-off;
  for (int i=0;i<rem;++i) block[i]=msg[off+i];
  block[rem++]=0x80;
  if (rem>56){
    for (int i=rem;i<64;++i) block[i]=0;
    signed int W[80];
    for (int i=0;i<16;++i){const signed char* p=block+4*i;W[i]=((signed int)p[0]<<24)|((signed int)p[1]<<16)|((signed int)p[2]<<8)|((signed int)p[3]);}
    for (int i=16;i<80;++i) W[i]=W[i-3]^W[i-8]^W[i-14]^W[i-16];
    signed int A=h0,B=h1,C=h2,D=h3,E=h4,temp;
    for (int i=0;i<20;++i){temp=ROL32(A,5)+F1(B,C,D)+E+W[i]+0x5a827999U;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    for (int i=20;i<40;++i){temp=ROL32(A,5)+F2(B,C,D)+E+W[i]+0x6ed9eba1U;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    for (int i=40;i<60;++i){temp=ROL32(A,5)+F3(B,C,D)+E+W[i]+0x8f1bbcdcU;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    for (int i=60;i<80;++i){temp=ROL32(A,5)+F4(B,C,D)+E+W[i]+0xca62c1d6U;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    h0+=A;h1+=B;h2+=C;h3+=D;h4+=E;
    rem=0;
  }
  for (int i=rem;i<56;++i) block[i]=0;
  block[56]=(signed char)((bitlen>>56)&0xFF);
  block[57]=(signed char)((bitlen>>48)&0xFF);
  block[58]=(signed char)((bitlen>>40)&0xFF);
  block[59]=(signed char)((bitlen>>32)&0xFF);
  block[60]=(signed char)((bitlen>>24)&0xFF);
  block[61]=(signed char)((bitlen>>16)&0xFF);
  block[62]=(signed char)((bitlen>>8)&0xFF);
  block[63]=(signed char)(bitlen&0xFF);
  {
    signed int W[80];
    for (int i=0;i<16;++i){const signed char* p=block+4*i;W[i]=((signed int)p[0]<<24)|((signed int)p[1]<<16)|((signed int)p[2]<<8)|((signed int)p[3]);}
    for (int i=16;i<80;++i) W[i]=W[i-3]^W[i-8]^W[i-14]^W[i-16];
    signed int A=h0,B=h1,C=h2,D=h3,E=h4,temp;
    for (int i=0;i<20;++i){temp=ROL32(A,5)+F1(B,C,D)+E+W[i]+0x5a827999U;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    for (int i=20;i<40;++i){temp=ROL32(A,5)+F2(B,C,D)+E+W[i]+0x6ed9eba1U;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    for (int i=40;i<60;++i){temp=ROL32(A,5)+F3(B,C,D)+E+W[i]+0x8f1bbcdcU;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    for (int i=60;i<80;++i){temp=ROL32(A,5)+F4(B,C,D)+E+W[i]+0xca62c1d6U;E=D;D=C;C=ROL32(B,30);B=A;A=temp;}
    h0+=A;h1+=B;h2+=C;h3+=D;h4+=E;
  }
  out[0]=h0; out[1]=h1; out[2]=h2; out[3]=h3; out[4]=h4;
}

static std::string digest_to_hex(const signed int d[5]) {
  std::ostringstream oss;
  oss << std::hex << std::setfill('0');
  for (int i=0;i<5;++i) {
    if (i) oss << ' ';
    oss << std::setw(8) << d[i];
  }
  return oss.str();
}

int main() {
  const char* tv[5] = {
    "",
    "abc",
    "message digest",
    "abcdefghijklmnopqrstuvwxyz",
    "abcdbcdecdefdefgefghfghigh"
  };

  bool global_pass = true;
  std::vector<std::string> local_results;

  for (int t=0;t<5;++t) {
    const char* msg = tv[t];
    int len = (int)std::strlen(msg);

    signed int golden[5];
    ref_sha0((const BYTE*)msg, len, golden);

    signed int actual[5];
    sha_process((const BYTE*)msg, len, actual);

    bool local_pass = true;
    for (int i=0;i<5;++i) if (actual[i] != golden[i]) local_pass = false;
    if (!local_pass) global_pass = false;

    /* 估算 N_INST: 需要的 512-bit block 数（含填充） */
    signed long long total_bits  = (signed long long)len * 8ULL + 1 + 64;
    signed long long total_bytes = (total_bits + 7ULL) >> 3;
    signed long long n_inst      = (total_bytes + 63ULL) / 64ULL;

    std::string input_str  = std::string(msg);
    std::string actual_str = digest_to_hex(actual);
    std::string golden_str = digest_to_hex(golden);

    std::stringstream result_line;
    result_line << "LOCAL_CHECK" << (t + 1) << ": "
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
