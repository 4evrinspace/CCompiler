#include "riscv.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

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

int get_variable_offset(const char* name) {
    // Simple offset calculation (replace with symbol table lookup)
    int base_offset = 8;
    int offset = base_offset + (name[0] - 'a') * 4;
    return offset;
}

void generate_riscv_code(ASTNode* node, FILE* output) {
    if (!node) return;

    switch (node->type) {
        case NODE_FUNCTION:
            generate_function_prologue(node->value, output);
            generate_statement(node->right, output);
            generate_function_epilogue(output);
            break;
        default:
            fprintf(stderr, "Error: Top level node is not a function\n");
            exit(1);
    }
}

void generate_function_prologue(const char* func_name, FILE* output) {
    fprintf(output, "    .text\n");
    fprintf(output, "    .globl %s\n", func_name);
    fprintf(output, "%s:\n", func_name);
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
    if (!node) {
        fprintf(output, "    li %s, 0\n", get_register_name(dest_reg));
        return;
    }

    switch (node->type) {
        case NODE_EXPRESSION:
            if (node->value && (isdigit(node->value[0]) || (node->value[0] == '-' && isdigit(node->value[1])))) {
                fprintf(output, "    li %s, %s\n", get_register_name(dest_reg), node->value);
            } else if (node->value && isalpha(node->value[0])) {
                int offset = get_variable_offset(node->value);
                fprintf(output, "    lw %s, -%d(s0)\n", get_register_name(dest_reg), offset);
            } else if (node->left && node->right) {
                RiscvReg left_reg = allocate_register();
                RiscvReg right_reg = allocate_register();
                generate_expression(node->left, output, left_reg);
                generate_expression(node->right, output, right_reg);
                if (node->value) {
                    if (strcmp(node->value, "+") == 0) {
                        fprintf(output, "    add %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                    } else if (strcmp(node->value, "-") == 0) {
                        fprintf(output, "    sub %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                    } else if (strcmp(node->value, "*") == 0) {
                        fprintf(output, "    mul %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                    } else if (strcmp(node->value, "/") == 0) {
                        fprintf(output, "    div %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                    } else if (strcmp(node->value, "%") == 0) {
                        fprintf(output, "    rem %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                    } else if (strcmp(node->value, "==") == 0) {
                        fprintf(output, "    xor %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                        fprintf(output, "    seqz %s, %s\n", get_register_name(dest_reg), get_register_name(dest_reg));
                    } else if (strcmp(node->value, "!=") == 0) {
                        fprintf(output, "    xor %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                        fprintf(output, "    snez %s, %s\n", get_register_name(dest_reg), get_register_name(dest_reg));
                    } else if (strcmp(node->value, "<") == 0) {
                        fprintf(output, "    slt %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                    } else if (strcmp(node->value, ">") == 0) {
                        fprintf(output, "    slt %s, %s, %s\n", get_register_name(dest_reg), get_register_name(right_reg), get_register_name(left_reg));
                    } else if (strcmp(node->value, "<=") == 0) {
                        fprintf(output, "    slt %s, %s, %s\n", get_register_name(dest_reg), get_register_name(right_reg), get_register_name(left_reg));
                        fprintf(output, "    xori %s, %s, 1\n", get_register_name(dest_reg), get_register_name(dest_reg));
                    } else if (strcmp(node->value, ">=") == 0) {
                        fprintf(output, "    slt %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                        fprintf(output, "    xori %s, %s, 1\n", get_register_name(dest_reg), get_register_name(dest_reg));
                    } else if (strcmp(node->value, "&&") == 0) {
                         fprintf(output, "    snez %s, %s\n", get_register_name(left_reg), get_register_name(left_reg));
                         fprintf(output, "    snez %s, %s\n", get_register_name(right_reg), get_register_name(right_reg));
                         fprintf(output, "    and %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                    } else if (strcmp(node->value, "||") == 0) {
                         fprintf(output, "    or %s, %s, %s\n", get_register_name(dest_reg), get_register_name(left_reg), get_register_name(right_reg));
                         fprintf(output, "    snez %s, %s\n", get_register_name(dest_reg), get_register_name(dest_reg));
                    }
                }
                free_register(left_reg);
                free_register(right_reg);
            } else if (node->right && node->value && strcmp(node->value, "!") == 0) {
                 generate_expression(node->right, output, dest_reg);
                 fprintf(output, "    seqz %s, %s\n", get_register_name(dest_reg), get_register_name(dest_reg));
            } else if (node->right && node->value && strcmp(node->value, "-") == 0) {
                 generate_expression(node->right, output, dest_reg);
                 fprintf(output, "    neg %s, %s\n", get_register_name(dest_reg), get_register_name(dest_reg));
            } else {
                 fprintf(output, "    li %s, 0\n", get_register_name(dest_reg));
            }
            break;
        case NODE_FUNCTION_CALL:
            if (node->value) {
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
            } else {
                fprintf(output, "    li %s, 0\n", get_register_name(dest_reg));
            }
            break;
        case NODE_ASSIGNMENT:
             if (node->value) { // Simple variable assignment
                 int offset = get_variable_offset(node->value);
                 generate_expression(node->right, output, dest_reg);
                 fprintf(output, "    sw %s, -%d(s0)\n", get_register_name(dest_reg), offset);
             } else if (node->left && node->left->type == NODE_ARRAY_ACCESS) { // Array assignment
                 RiscvReg index_reg = allocate_register();
                 RiscvReg addr_reg = allocate_register();
                 generate_expression(node->right, output, dest_reg); // Value to store
                 generate_expression(node->left->left, output, index_reg); // Index
                 int offset = get_variable_offset(node->left->value);
                 fprintf(output, "    slli %s, %s, 2\n", get_register_name(index_reg), get_register_name(index_reg));
                 fprintf(output, "    addi %s, s0, -%d\n", get_register_name(addr_reg), offset);
                 fprintf(output, "    add %s, %s, %s\n", get_register_name(addr_reg), get_register_name(addr_reg), get_register_name(index_reg));
                 fprintf(output, "    sw %s, 0(%s)\n", get_register_name(dest_reg), get_register_name(addr_reg));
                 free_register(index_reg);
                 free_register(addr_reg);
             }
             break;
        case NODE_ARRAY_ACCESS:
            if (node->value) {
                RiscvReg index_reg = allocate_register();
                RiscvReg addr_reg = allocate_register();
                generate_expression(node->left, output, index_reg);
                int offset = get_variable_offset(node->value);
                fprintf(output, "    slli %s, %s, 2\n", get_register_name(index_reg), get_register_name(index_reg));
                fprintf(output, "    addi %s, s0, -%d\n", get_register_name(addr_reg), offset);
                fprintf(output, "    add %s, %s, %s\n", get_register_name(addr_reg), get_register_name(addr_reg), get_register_name(index_reg));
                fprintf(output, "    lw %s, 0(%s)\n", get_register_name(dest_reg), get_register_name(addr_reg));
                free_register(index_reg);
                free_register(addr_reg);
            }
            break;
        default:
            fprintf(output, "    li %s, 0 \n", get_register_name(dest_reg));
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
        case NODE_FOR:
            generate_for(node, output);
            break;
        case NODE_RETURN:
            generate_return(node, output);
            break;
        case NODE_EXPRESSION:
        case NODE_ASSIGNMENT:
        case NODE_FUNCTION_CALL:
            generate_expression(node, output, A0);
            break;
        case NODE_DECLARATION:
             if (node->right) {
                 RiscvReg value_reg = allocate_register();
                 generate_expression(node->right, output, value_reg);
                 int offset = get_variable_offset(node->value);
                 fprintf(output, "    sw %s, -%d(s0)\n", get_register_name(value_reg), offset);
                 free_register(value_reg);
             }
            break;
        default:
             break;
    }
    if (node->next) {
        generate_statement(node->next, output);
    }
}

void generate_if(ASTNode* node, FILE* output) {
    int else_label = label_counter++;
    int end_label = label_counter++;
    RiscvReg cond_reg = allocate_register();
    generate_expression(node->left, output, cond_reg);
    fprintf(output, "    beqz %s, .L%d\n", get_register_name(cond_reg), else_label);
    generate_statement(node->right, output);
    fprintf(output, "    j .L%d\n", end_label);
    fprintf(output, ".L%d:\n", else_label);
    if (node->next && node->next->type == NODE_ELSE) {
        generate_statement(node->next->right, output);
        node->next = node->next->next;
    }
    fprintf(output, ".L%d:\n", end_label);
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
    if (node && node->left) {
        generate_expression(node->left, output, A0);
    } else {
        fprintf(output, "    li a0, 0\n");
    }
    fprintf(output, "    ret\n");
}

void generate_for(ASTNode* node, FILE* output) {
    int start_label = label_counter++;
    int end_label = label_counter++;
    if (node->left) {
        generate_expression(node->left, output, A0);
    }
    fprintf(output, ".L%d:\n", start_label);
    ASTNode* condition = node->right;
    if (condition) {
        RiscvReg cond_reg = allocate_register();
        generate_expression(condition, output, cond_reg);
        fprintf(output, "    beqz %s, .L%d\n", get_register_name(cond_reg), end_label);
        ASTNode* iteration = condition->next;
        ASTNode* body = NULL;
        if (iteration) {
            body = iteration->next;
        }
        if (body) {
            generate_statement(body, output);
        }
        if (iteration) {
            generate_expression(iteration, output, A0);
        }
        fprintf(output, "    j .L%d\n", start_label);
        free_register(cond_reg);
    }
    fprintf(output, ".L%d:\n", end_label);
} 