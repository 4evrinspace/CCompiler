#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef enum {
    TOKEN_INT,
    TOKEN_CHAR,
    TOKEN_IDENTIFIER,
    TOKEN_NUMBER,
    TOKEN_STRING,
    TOKEN_OPERATOR,
    TOKEN_KEYWORD,
    TOKEN_SYMBOL
} TokenType;


typedef enum {
    NODE_PROGRAM,
    NODE_FUNCTION,
    NODE_DECLARATION,
    NODE_ASSIGNMENT,
    NODE_EXPRESSION,
    NODE_STATEMENT,
    NODE_IF,
    NODE_ELSE,
    NODE_WHILE,
    NODE_FOR,
    NODE_RETURN,
    NODE_FUNCTION_CALL,
    NODE_TYPE,
    NODE_STRING,
    NODE_CHAR,
    NODE_ARRAY_ACCESS
} NodeType;

typedef struct ASTNode {
    NodeType type;
    char* value;
    struct ASTNode* left;
    struct ASTNode* right;
    struct ASTNode* next;
} ASTNode;


typedef struct Symbol {
    char* name;
    TokenType type;
    int scope;
    struct Symbol* next;
} Symbol;


ASTNode* create_node(NodeType type, char* value);
void free_ast(ASTNode* node);
void print_ast(ASTNode* node, int level);
void yyerror(const char* s);
int yylex(void);
int yyparse(void);


extern FILE* yyin;
extern int yylineno;
extern ASTNode* root;
