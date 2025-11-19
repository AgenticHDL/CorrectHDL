// sha.cpp : implementation (no header, HLS-friendly, W=16 circular buffer)

typedef signed char BYTE;
typedef signed int  INT32;


#ifndef MAX_INPUT_BYTES
#define MAX_INPUT_BYTES 64 
#endif

/* --- Global state --- */
INT32 sha_info_digest[5];                   /* message digest */
INT32 sha_info_count_lo, sha_info_count_hi; /* 64-bit bit count */
static BYTE sha_info_block[64];             /* 512-bit work buffer */

/* --- Macros --- */
#define SHA_BLOCKSIZE 64

#define f1(x,y,z) ((x & y) | (~x & z))
#define f2(x,y,z) (x ^ y ^ z)
#define f3(x,y,z) ((x & y) | (x & z) | (y & z))
#define f4(x,y,z) (x ^ y ^ z)

#define CONST1 0x5a827999UL
#define CONST2 0x6ed9eba1UL
#define CONST3 0x8f1bbcdcUL
#define CONST4 0xca62c1d6UL

#define ROT32(x,n) ((x << (n)) | (x >> (32 - (n))))

/* --- Core transform with 16-word circular W --- */
static void sha_transform(void)
{
  INT32 W[16];
  INT32 A, B, C, D, E, temp;
  const BYTE *data = sha_info_block;


  for (int i = 0; i < 16; ++i) {
    int k = 4*i;
    W[i] = ((INT32)data[k]   << 24) |
           ((INT32)data[k+1] << 16) |
           ((INT32)data[k+2] <<  8) |
           ((INT32)data[k+3]);
  }

  A = sha_info_digest[0];
  B = sha_info_digest[1];
  C = sha_info_digest[2];
  D = sha_info_digest[3];
  E = sha_info_digest[4];

  for (int i = 0; i < 80; ++i) {
    INT32 Wi;
    if (i >= 16) {

      Wi = W[(i-3)&15] ^ W[(i-8)&15] ^ W[(i-14)&15] ^ W[i&15];
      W[i&15] = Wi;
    } else {
      Wi = W[i];
    }

    INT32 F, K;
    if (i < 20)      { F = f1(B,C,D); K = CONST1; }
    else if (i < 40) { F = f2(B,C,D); K = CONST2; }
    else if (i < 60) { F = f3(B,C,D); K = CONST3; }
    else             { F = f4(B,C,D); K = CONST4; }

    temp = ROT32(A,5) + F + E + Wi + K;
    E = D;
    D = C;
    C = ROT32(B,30);
    B = A;
    A = temp;
  }

  sha_info_digest[0] += A;
  sha_info_digest[1] += B;
  sha_info_digest[2] += C;
  sha_info_digest[3] += D;
  sha_info_digest[4] += E;
}

/* --- API --- */
void sha_init(void)
{
  sha_info_digest[0] = 0x67452301UL;
  sha_info_digest[1] = 0xefcdab89UL;
  sha_info_digest[2] = 0x98badcfeUL;
  sha_info_digest[3] = 0x10325476UL;
  sha_info_digest[4] = 0xc3d2e1f0UL;
  sha_info_count_lo  = 0UL;
  sha_info_count_hi  = 0UL;
  for (int i = 0; i < 64; ++i) sha_info_block[i] = 0;
}

static void sha_update(const BYTE *buffer, int count)
{
  if ((sha_info_count_lo + ((INT32)count << 3)) < sha_info_count_lo)
    ++sha_info_count_hi;
  sha_info_count_lo += (INT32)count << 3;
  sha_info_count_hi += (INT32)count >> 29;

  while (count >= SHA_BLOCKSIZE) {
    for (int i = 0; i < 64; ++i) sha_info_block[i] = buffer[i];
    sha_transform();
    buffer += SHA_BLOCKSIZE;
    count  -= SHA_BLOCKSIZE;
  }
  for (int i = 0; i < count; ++i) sha_info_block[i] = buffer[i];
}

void sha_final(void)
{
  INT32 lo_bit_count = sha_info_count_lo;
  INT32 hi_bit_count = sha_info_count_hi;
  BYTE *data = sha_info_block;

  int count = (int)((lo_bit_count >> 3) & 0x3f);
  data[count++] = 0x80;

  if (count > 56) {
    for (int i = count; i < 64; ++i) data[i] = 0;
    sha_transform();
    for (int i = 0; i < 56; ++i) data[i] = 0;
  } else {
    for (int i = count; i < 56; ++i) data[i] = 0;
  }

  data[56] = (BYTE)((hi_bit_count >> 24) & 0xFF);
  data[57] = (BYTE)((hi_bit_count >> 16) & 0xFF);
  data[58] = (BYTE)((hi_bit_count >>  8) & 0xFF);
  data[59] = (BYTE)( hi_bit_count        & 0xFF);
  data[60] = (BYTE)((lo_bit_count >> 24) & 0xFF);
  data[61] = (BYTE)((lo_bit_count >> 16) & 0xFF);
  data[62] = (BYTE)((lo_bit_count >>  8) & 0xFF);
  data[63] = (BYTE)( lo_bit_count        & 0xFF);

  sha_transform();
}

#pragma hls_design top
#pragma design_goal area
void sha_process(const BYTE in[MAX_INPUT_BYTES], int len, signed int out[5])
{
  if (len < 0) len = 0;
  if (len > MAX_INPUT_BYTES) len = MAX_INPUT_BYTES;

  sha_init();

  int offset = 0;
  const int MAX_BLOCKS = (MAX_INPUT_BYTES / 64);
  for (int blk = 0; blk < MAX_BLOCKS; ++blk) {
    if (offset + 64 <= len) {
      sha_update(in + offset, 64);
      offset += 64;
    } else {
      break;
    }
  }


  if (offset < len) {
    sha_update(in + offset, len - offset);
  }

  sha_final();

  out[0] = (signed int)sha_info_digest[0];
  out[1] = (signed int)sha_info_digest[1];
  out[2] = (signed int)sha_info_digest[2];
  out[3] = (signed int)sha_info_digest[3];
  out[4] = (signed int)sha_info_digest[4];
}
