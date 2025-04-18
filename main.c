#include "compiler.h"
#include "riscv.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    FILE* input_file = fopen(argv[1], "r");
    if (!input_file) {
        fprintf(stderr, "Error: Cannot open file %s\n", argv[1]);
        return 1;
    }

    yyin = input_file;
    
    printf("Starting compilation of %s...\n", argv[1]);
    
    if (yyparse() == 0) {
        printf("Parsing successful!\n");
        
        // Debug: Print root node information
        if (root) {
            printf("DEBUG: Root node exists, type: %d\n", root->type);
            if (root->value) {
                printf("DEBUG: Root node value: %s\n", root->value);
            } else {
                printf("DEBUG: Root node has no value\n");
            }
            if (root->left) {
                printf("DEBUG: Root node has left child\n");
            }
            if (root->right) {
                printf("DEBUG: Root node has right child\n");
            }
        } else {
            printf("DEBUG: Root node is NULL\n");
        }
        
        char* output_filename = "output.s";
        FILE* output_file = fopen(output_filename, "w");
        if (!output_file) {
            fprintf(stderr, "Error: Cannot create output file %s\n", output_filename);
            fclose(input_file);
            return 1;
        }
        
        printf("DEBUG: Calling generate_riscv_code with root node\n");
        generate_riscv_code(root, output_file);
        fclose(output_file);
        printf("RISC-V assembly generated in %s\n", output_filename);
    } else {
        fprintf(stderr, "Compilation failed at line %d\n", yylineno);
    }

    free_ast(root);
    fclose(input_file);
    return 0;
} 