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
    
    if (yyparse() == 0) {
        char* output_filename = "output.s";
        FILE* output_file = fopen(output_filename, "w");
        if (!output_file) {
            fprintf(stderr, "Error: Cannot create output file %s\n", output_filename);
            fclose(input_file);
            return 1;
        }
        
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