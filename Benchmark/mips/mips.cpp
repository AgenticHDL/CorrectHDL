#include <cstdint>

#define R 0
#define ADDU 33
#define SUBU 35
#define SLL 0
#define SLT 42
#define JR 8
#define J 2
#define JAL 3
#define ADDIU 9
#define ANDI 12
#define ORI 13
#define LW 35
#define SW 43
#define LUI 15
#define BEQ 4
#define SLTI 10

#define IADDR(x) (((x)&0x000000ffU)>>2)
#define DADDR(x) (((x)&0x000000ffU)>>2)

static const uint32_t imem[44] = {
  0x8fa40000,
  0x27a50004,
  0x24a60004,
  0x00041080,
  0x00c23021,
  0x0c100016,
  0x00000000,
  0x3402000a,
  0x0000000c,
  0x3c011001,
  0x34280000,
  0x00044880,
  0x01094821,
  0x8d2a0000,
  0x00055880,
  0x010b5821,
  0x8d6c0000,
  0x018a682a,
  0x11a00003,
  0xad2c0000,
  0xad6a0000,
  0x03e00008,
  0x27bdfff4,
  0xafbf0008,
  0xafb10004,
  0xafb00000,
  0x24100000,
  0x2a080008,
  0x1100000b,
  0x26110001,
  0x2a280008,
  0x11000006,
  0x26040000,
  0x26250000,
  0x0c100009,
  0x26310001,
  0x0810001e,
  0x26100001,
  0x0810001b,
  0x8fbf0008,
  0x8fb10004,
  0x8fb00000,
  0x27bd000c,
  0x03e00008
};

#pragma hls_design top
extern "C" void mips_sort(const int A_in[8], int out[8], int* n_inst_out) {
  int32_t reg[32];
  int32_t dmem[64];
  int32_t Hi = 0;
  int32_t Lo = 0;
  uint32_t pc = 0;
  uint32_t ins = 0;
  int32_t n_inst = 0;

  for (int i = 0; i < 32; ++i) reg[i] = 0;
  reg[29] = 0x7fffeffc;
  for (int i = 0; i < 64; ++i) dmem[i] = 0;
  for (int i = 0; i < 8; ++i) dmem[i] = A_in[i];

  pc = 0x00400000;

  for (;;) {
    ins = imem[IADDR(pc)];
    pc += 4;
    uint32_t op = ins >> 26;

    if (op == R) {
      int funct = ins & 0x3f;
      int shamt = (ins >> 6) & 0x1f;
      int rd = (ins >> 11) & 0x1f;
      int rt = (ins >> 16) & 0x1f;
      int rs = (ins >> 21) & 0x1f;

      if (funct == ADDU) {
        reg[rd] = reg[rs] + reg[rt];
      } else if (funct == SUBU) {
        reg[rd] = reg[rs] - reg[rt];
      } else if (funct == SLL) {
        reg[rd] = reg[rt] << shamt;
      } else if (funct == SLT) {
        reg[rd] = (reg[rs] < reg[rt]) ? 1 : 0;
      } else if (funct == JR) {
        pc = (uint32_t)reg[rs];
      } else {
        pc = 0;
      }
    } else if (op == J) {
      uint32_t tgtadr = ins & 0x03ffffffU;
      pc = tgtadr << 2;
    } else if (op == JAL) {
      uint32_t tgtadr = ins & 0x03ffffffU;
      reg[31] = (int32_t)pc;
      pc = tgtadr << 2;
    } else {
      int32_t address = (int16_t)(ins & 0xffff);
      int rt = (ins >> 16) & 0x1f;
      int rs = (ins >> 21) & 0x1f;

      if (op == ADDIU) {
        reg[rt] = reg[rs] + address;
      } else if (op == ANDI) {
        reg[rt] = reg[rs] & (uint16_t)address;
      } else if (op == ORI) {
        reg[rt] = reg[rs] | (uint16_t)address;
      } else if (op == LW) {
        int32_t addr = reg[rs] + address;
        reg[rt] = dmem[DADDR(addr)];
      } else if (op == SW) {
        int32_t addr = reg[rs] + address;
        dmem[DADDR(addr)] = reg[rt];
      } else if (op == LUI) {
        reg[rt] = ((int32_t)address) << 16;
      } else if (op == BEQ) {
        if (reg[rs] == reg[rt]) pc = pc - 4 + ((uint32_t)((int32_t)address << 2));
      } else if (op == SLTI) {
        reg[rt] = (reg[rs] < (int32_t)address) ? 1 : 0;
      } else {
        pc = 0;
      }
    }

    reg[0] = 0;
    n_inst++;

    if (pc == 0) break;
  }

  for (int i = 0; i < 8; ++i) out[i] = dmem[i];
  if (n_inst_out) *n_inst_out = n_inst;
}
