#pragma once

#include "compiler.h"
#include <stdio.h>


typedef enum {
    ZERO,   // x0
    RA,     // x1
    SP,     // x2
    GP,     // x3
    TP,     // x4
    T0,     // x5
    T1,     // x6
    T2,     // x7
    S0,     // x8
    S1,     // x9
    A0,     // x10
    A1,     // x11
    A2,     // x12
    A3,     // x13
    A4,     // x14
    A5,     // x15
    A6,     // x16
    A7,     // x17
    S2,     // x18
    S3,     // x19
    S4,     // x20
    S5,     // x21
    S6,     // x22
    S7,     // x23
    S8,     // x24
    S9,     // x25
    S10,    // x26
    S11,    // x27
    T3,     // x28
    T4,     // x29
    T5,     // x30
    T6      // x31
} RiscvReg;


void generate_riscv_code(ASTNode* node, FILE* output);
void generate_function_prologue(const char* func_name, FILE* output);
void generate_function_epilogue(FILE* output);
void generate_expression(ASTNode* node, FILE* output, RiscvReg dest_reg);
void generate_statement(ASTNode* node, FILE* output);
void generate_if(ASTNode* node, FILE* output);
void generate_while(ASTNode* node, FILE* output);
void generate_for(ASTNode* node, FILE* output);
void generate_return(ASTNode* node, FILE* output);


const char* get_register_name(RiscvReg reg);
RiscvReg allocate_register(void);
void free_register(RiscvReg reg);

