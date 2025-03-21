%{
#include "compiler.h"
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char* s);
int yylex(void);

ASTNode* root = NULL;
%}

%union {
    int num;
    char* str;
    ASTNode* node;
}

%token <num> NUMBER
%token <str> IDENTIFIER
%token INT CHAR VOID
%token IF ELSE WHILE RETURN
%token PLUS MINUS TIMES DIVIDE
%token ASSIGN EQ NEQ LT GT LE GE
%token LPAREN RPAREN LBRACE RBRACE
%token SEMICOLON COMMA

%type <node> program function declaration statement expression parameter_list argument_list

%%

program
    : function
    | program function
    ;

function
    : type IDENTIFIER LPAREN parameter_list RPAREN LBRACE statements RBRACE
    {
        $$ = create_node(NODE_FUNCTION, $2);
        $$->left = $4;  // parameters
        $$->right = $7; // statements
    }
    ;

parameter_list
    : /* empty */
    | type IDENTIFIER
    {
        $$ = create_node(NODE_DECLARATION, $2);
    }
    | parameter_list COMMA type IDENTIFIER
    {
        $1->next = create_node(NODE_DECLARATION, $4);
        $$ = $1;
    }
    ;

type
    : INT
    | CHAR
    | VOID
    ;

statements
    : statement
    | statements statement
    {
        $1->next = $2;
        $$ = $1;
    }
    ;

statement
    : declaration SEMICOLON
    | expression SEMICOLON
    | IF LPAREN expression RPAREN statement
    {
        $$ = create_node(NODE_IF, NULL);
        $$->left = $3;
        $$->right = $5;
    }
    | WHILE LPAREN expression RPAREN statement
    {
        $$ = create_node(NODE_WHILE, NULL);
        $$->left = $3;
        $$->right = $5;
    }
    | RETURN expression SEMICOLON
    {
        $$ = create_node(NODE_RETURN, NULL);
        $$->left = $2;
    }
    ;

declaration
    : type IDENTIFIER
    {
        $$ = create_node(NODE_DECLARATION, $2);
    }
    | type IDENTIFIER ASSIGN expression
    {
        $$ = create_node(NODE_DECLARATION, $2);
        $$->right = $4;
    }
    ;

expression
    : IDENTIFIER ASSIGN expression
    {
        $$ = create_node(NODE_ASSIGNMENT, $1);
        $$->right = $3;
    }
    | IDENTIFIER LPAREN argument_list RPAREN
    {
        $$ = create_node(NODE_FUNCTION_CALL, $1);
        $$->left = $3;
    }
    | expression PLUS expression
    | expression MINUS expression
    | expression TIMES expression
    | expression DIVIDE expression
    | expression EQ expression
    | expression NEQ expression
    | expression LT expression
    | expression GT expression
    | expression LE expression
    | expression GE expression
    {
        $$ = create_node(NODE_EXPRESSION, NULL);
        $$->left = $1;
        $$->right = $3;
    }
    | IDENTIFIER
    | NUMBER
    {
        $$ = create_node(NODE_EXPRESSION, NULL);
        $$->value = $1;
    }
    | LPAREN expression RPAREN
    {
        $$ = $2;
    }
    ;

argument_list
    : /* empty */
    | expression
    {
        $$ = $1;
    }
    | argument_list COMMA expression
    {
        $1->next = $3;
        $$ = $1;
    }
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
}

ASTNode* create_node(NodeType type, char* value) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->type = type;
    node->value = value;
    node->left = NULL;
    node->right = NULL;
    node->next = NULL;
    return node;
}

void free_ast(ASTNode* node) {
    if (node == NULL) return;
    free_ast(node->left);
    free_ast(node->right);
    free_ast(node->next);
    free(node->value);
    free(node);
}

void print_ast(ASTNode* node, int level) {
    if (node == NULL) return;
    
    for (int i = 0; i < level; i++) printf("  ");
    printf("Node type: %d", node->type);
    if (node->value) printf(", Value: %s", node->value);
    printf("\n");
    
    print_ast(node->left, level + 1);
    print_ast(node->right, level + 1);
    print_ast(node->next, level);
} 