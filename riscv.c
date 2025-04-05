#include "riscv.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


static int register_used[32] = {0};
static int label_counter = 0;
static int stack_offset = 0;

const char* get_register_name(RiscvReg reg) {
    static const char* names[] = {
        "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
        "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
        "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
        "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
    };
    return names[reg];
}

RiscvReg allocate_register(void) {

    for (int i = T0; i <= T6; i++) {
        if (!register_used[i]) {
            register_used[i] = 1;
            return (RiscvReg)i;
        }
    }
    fprintf(stderr, "Error: No free registers available\n");
    exit(1);
}

void free_register(RiscvReg reg) {
    register_used[reg] = 0;
}

void generate_riscv_code(ASTNode* node, FILE* output) {
    if (!node) return;
    
    switch (node->type) {
        case NODE_FUNCTION:
            generate_function_prologue(output);

            ASTNode* param = node->left;
            int param_offset = 0;
            while (param) {

                fprintf(output, "    sw a%d, %d(sp)\n", param_offset, -16 - param_offset * 4);
                param_offset++;
                param = param->next;
            }
            generate_statement(node->right, output);
            generate_function_epilogue(output);
            break;
        default:
            generate_statement(node, output);
    }
}

void generate_function_prologue(FILE* output) {
    fprintf(output, "    .text\n");
    fprintf(output, "    .globl main\n");
    fprintf(output, "main:\n");
    fprintf(output, "    addi sp, sp, -16\n");  
    fprintf(output, "    sw ra, 12(sp)\n");    
    fprintf(output, "    sw s0, 8(sp)\n");      
    fprintf(output, "    addi s0, sp, 16\n");   
}

void generate_function_epilogue(FILE* output) {
    fprintf(output, "    lw ra, 12(sp)\n");     
    fprintf(output, "    lw s0, 8(sp)\n");      
    fprintf(output, "    addi sp, sp, 16\n");   
    fprintf(output, "    ret\n");               
}

void generate_expression(ASTNode* node, FILE* output, RiscvReg dest_reg) {
    if (!node) return;
    
    switch (node->type) {
        case NODE_EXPRESSION:
            if (node->value) {
                
                fprintf(output, "    li %s, %s\n", get_register_name(dest_reg), node->value);
            } else {
                
                RiscvReg left_reg = allocate_register();
                RiscvReg right_reg = allocate_register();
                
                generate_expression(node->left, output, left_reg);
                generate_expression(node->right, output, right_reg);
                
               
                if (strcmp(node->value, "+") == 0) {
                    fprintf(output, "    add %s, %s, %s\n", 
                            get_register_name(dest_reg),
                            get_register_name(left_reg),
                            get_register_name(right_reg));
                } else if (strcmp(node->value, "-") == 0) {
                    fprintf(output, "    sub %s, %s, %s\n",
                            get_register_name(dest_reg),
                            get_register_name(left_reg),
                            get_register_name(right_reg));
                } else if (strcmp(node->value, "*") == 0) {
                    fprintf(output, "    mul %s, %s, %s\n",
                            get_register_name(dest_reg),
                            get_register_name(left_reg),
                            get_register_name(right_reg));
                } else if (strcmp(node->value, "/") == 0) {
                    fprintf(output, "    div %s, %s, %s\n",
                            get_register_name(dest_reg),
                            get_register_name(left_reg),
                            get_register_name(right_reg));
                }
                
                free_register(left_reg);
                free_register(right_reg);
            }
            break;
            
        case NODE_FUNCTION_CALL:
            
            ASTNode* arg = node->left;
            int arg_reg = A0;
            while (arg && arg_reg <= A7) {
                generate_expression(arg, output, (RiscvReg)arg_reg);
                arg = arg->next;
                arg_reg++;
            }
            
            
            fprintf(output, "    call %s\n", node->value);
            
            
            if (dest_reg != A0) {
                fprintf(output, "    mv %s, a0\n", get_register_name(dest_reg));
            }
            break;
            
        case NODE_ASSIGNMENT:
            
            generate_expression(node->right, output, dest_reg);
            
            
            fprintf(output, "    sw %s, -%d(s0)\n", 
                    get_register_name(dest_reg),
                    (int)(strlen(node->value) + 1) * 4);  
            break;
            
        default:
            fprintf(stderr, "Error: Unsupported expression type\n");
            exit(1);
    }
}

void generate_statement(ASTNode* node, FILE* output) {
    if (!node) return;
    
    switch (node->type) {
        case NODE_IF:
            generate_if(node, output);
            break;
        case NODE_WHILE:
            generate_while(node, output);
            break;
        case NODE_RETURN:
            generate_return(node, output);
            break;
        case NODE_EXPRESSION:
            generate_expression(node, output, A0);
            break;
        default:
            fprintf(stderr, "Error: Unsupported statement type\n");
            exit(1);
    }
}

void generate_if(ASTNode* node, FILE* output) {
    int label = label_counter++;
    RiscvReg cond_reg = allocate_register();
    
    generate_expression(node->left, output, cond_reg);
    fprintf(output, "    beqz %s, .L%d\n", get_register_name(cond_reg), label);
    generate_statement(node->right, output);
    fprintf(output, ".L%d:\n", label);
    
    free_register(cond_reg);
}

void generate_while(ASTNode* node, FILE* output) {
    int start_label = label_counter++;
    int end_label = label_counter++;
    RiscvReg cond_reg = allocate_register();
    
    fprintf(output, ".L%d:\n", start_label);
    generate_expression(node->left, output, cond_reg);
    fprintf(output, "    beqz %s, .L%d\n", get_register_name(cond_reg), end_label);
    generate_statement(node->right, output);
    fprintf(output, "    j .L%d\n", start_label);
    fprintf(output, ".L%d:\n", end_label);
    
    free_register(cond_reg);
}

void generate_return(ASTNode* node, FILE* output) {
    if (node->left) {
        generate_expression(node->left, output, A0);
    } else {
        fprintf(output, "    li a0, 0\n");
    }
} 