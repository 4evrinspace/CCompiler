%{
#include "compiler.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char* s);
int yylex(void);

char* my_strdup(const char* s) {
    char* result = malloc(strlen(s) + 1);
    if (result == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    strcpy(result, s);
    return result;
}

ASTNode* root = NULL;
%}

%union {
    int num;
    char* str;
    ASTNode* node;
}

%token <num> NUMBER
%token <str> IDENTIFIER STRING_LITERAL CHAR_LITERAL
%token INT CHAR VOID
%token IF ELSE WHILE FOR RETURN
%token PLUS MINUS TIMES DIVIDE MOD
%token ASSIGN PLUS_ASSIGN MINUS_ASSIGN
%token EQ NEQ LT GT LE GE AND OR NOT
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token SEMICOLON COMMA

%type <node> program function_def declaration statements statement
%type <node> expression assignment_expr logical_expr relational_expr
%type <node> additive_expr term factor function_call array_access
%type <node> type param_list params arg_list args if_statement
%type <node> while_statement for_statement return_statement

%%

program
    : function_def
    {
        $$ = $1;
        root = $$;
    }
    | program function_def
    {
        ASTNode* temp = $1;
        while(temp->next != NULL) {
            temp = temp->next;
        }
        temp->next = $2;
        $$ = $1;
    }
    ;

function_def
    : type IDENTIFIER LPAREN param_list RPAREN LBRACE statements RBRACE
    {
        $$ = create_node(NODE_FUNCTION, $2);
        $$->left = $4;
        $$->right = $7;
    }
    ;

param_list
    : params
    {
        $$ = $1;
    }
    | /* empty */
    {
        $$ = NULL;
    }
    ;

params
    : type IDENTIFIER
    {
        $$ = create_node(NODE_DECLARATION, $2);
    }
    | params COMMA type IDENTIFIER
    {
        ASTNode* param = create_node(NODE_DECLARATION, $4);
        ASTNode* temp = $1;
        while(temp->next != NULL) {
            temp = temp->next;
        }
        temp->next = param;
        $$ = $1;
    }
    ;

type
    : INT
    {
        $$ = create_node(NODE_TYPE, my_strdup("int"));
    }
    | CHAR
    {
        $$ = create_node(NODE_TYPE, my_strdup("char"));
    }
    | VOID
    {
        $$ = create_node(NODE_TYPE, my_strdup("void"));
    }
    ;

statements
    : statement
    {
        $$ = $1;
    }
    | statements statement
    {
        if ($1 == NULL) {
            $$ = $2;
        } else {
            ASTNode* temp = $1;
            while(temp->next != NULL) {
                temp = temp->next;
            }
            temp->next = $2;
            $$ = $1;
        }
    }
    | /* empty */
    {
        $$ = NULL;
    }
    ;

statement
    : expression SEMICOLON
    {
        $$ = $1;
    }
    | declaration SEMICOLON
    {
        $$ = $1;
    }
    | if_statement
    {
        $$ = $1;
    }
    | while_statement
    {
        $$ = $1;
    }
    | for_statement
    {
        $$ = $1;
    }
    | return_statement
    {
        $$ = $1;
    }
    | LBRACE statements RBRACE
    {
        $$ = $2;
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
    | type IDENTIFIER LBRACKET NUMBER RBRACKET
    {
        char* array_info = malloc(strlen($2) + 20);
        sprintf(array_info, "%s[%d]", $2, $4);
        $$ = create_node(NODE_DECLARATION, array_info);
    }
    ;

if_statement
    : IF LPAREN expression RPAREN statement
    {
        $$ = create_node(NODE_IF, NULL);
        $$->left = $3;
        $$->right = $5;
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        $$ = create_node(NODE_IF, NULL);
        $$->left = $3;
        $$->right = $5;
        ASTNode* else_node = create_node(NODE_ELSE, NULL);
        else_node->right = $7;
        $$->next = else_node;
    }
    ;

while_statement
    : WHILE LPAREN expression RPAREN statement
    {
        $$ = create_node(NODE_WHILE, NULL);
        $$->left = $3;
        $$->right = $5;
    }
    ;

for_statement
    : FOR LPAREN expression SEMICOLON expression SEMICOLON expression RPAREN statement
    {
        $$ = create_node(NODE_FOR, NULL);
        $$->left = $3;
        $$->right = $5;
        $5->next = $7;
        $7->next = $9;
    }
    ;

return_statement
    : RETURN expression SEMICOLON
    {
        $$ = create_node(NODE_RETURN, NULL);
        $$->left = $2;
    }
    | RETURN SEMICOLON
    {
        $$ = create_node(NODE_RETURN, NULL);
    }
    ;

expression
    : assignment_expr
    {
        $$ = $1;
    }
    ;

assignment_expr
    : logical_expr
    {
        $$ = $1;
    }
    | IDENTIFIER ASSIGN assignment_expr
    {
        $$ = create_node(NODE_ASSIGNMENT, $1);
        $$->right = $3;
    }
    | IDENTIFIER PLUS_ASSIGN assignment_expr
    {
        ASTNode* plus = create_node(NODE_EXPRESSION, my_strdup("+"));
        plus->left = create_node(NODE_EXPRESSION, $1);
        plus->right = $3;
        $$ = create_node(NODE_ASSIGNMENT, $1);
        $$->right = plus;
    }
    | IDENTIFIER MINUS_ASSIGN assignment_expr
    {
        ASTNode* minus = create_node(NODE_EXPRESSION, my_strdup("-"));
        minus->left = create_node(NODE_EXPRESSION, $1);
        minus->right = $3;
        $$ = create_node(NODE_ASSIGNMENT, $1);
        $$->right = minus;
    }
    | array_access ASSIGN assignment_expr
    {
        $$ = create_node(NODE_ASSIGNMENT, NULL);
        $$->left = $1;
        $$->right = $3;
    }
    ;

logical_expr
    : relational_expr
    {
        $$ = $1;
    }
    | logical_expr AND relational_expr
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("&&"));
        $$->left = $1;
        $$->right = $3;
    }
    | logical_expr OR relational_expr
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("||"));
        $$->left = $1;
        $$->right = $3;
    }
    ;

relational_expr
    : additive_expr
    {
        $$ = $1;
    }
    | relational_expr EQ additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("=="));
        $$->left = $1;
        $$->right = $3;
    }
    | relational_expr NEQ additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("!="));
        $$->left = $1;
        $$->right = $3;
    }
    | relational_expr LT additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("<"));
        $$->left = $1;
        $$->right = $3;
    }
    | relational_expr GT additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup(">"));
        $$->left = $1;
        $$->right = $3;
    }
    | relational_expr LE additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("<="));
        $$->left = $1;
        $$->right = $3;
    }
    | relational_expr GE additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup(">="));
        $$->left = $1;
        $$->right = $3;
    }
    ;

additive_expr
    : term
    {
        $$ = $1;
    }
    | additive_expr PLUS term
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("+"));
        $$->left = $1;
        $$->right = $3;
    }
    | additive_expr MINUS term
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("-"));
        $$->left = $1;
        $$->right = $3;
    }
    ;

term
    : factor
    {
        $$ = $1;
    }
    | term TIMES factor
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("*"));
        $$->left = $1;
        $$->right = $3;
    }
    | term DIVIDE factor
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("/"));
        $$->left = $1;
        $$->right = $3;
    }
    | term MOD factor
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("%"));
        $$->left = $1;
        $$->right = $3;
    }
    ;

factor
    : IDENTIFIER
    {
        $$ = create_node(NODE_EXPRESSION, $1);
    }
    | NUMBER
    {
        char buffer[20];
        sprintf(buffer, "%d", $1);
        $$ = create_node(NODE_EXPRESSION, my_strdup(buffer));
    }
    | STRING_LITERAL
    {
        $$ = create_node(NODE_STRING, $1);
    }
    | CHAR_LITERAL
    {
        $$ = create_node(NODE_CHAR, $1);
    }
    | LPAREN expression RPAREN
    {
        $$ = $2;
    }
    | NOT factor
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("!"));
        $$->right = $2;
    }
    | MINUS factor
    {
        $$ = create_node(NODE_EXPRESSION, my_strdup("-"));
        $$->right = $2;
    }
    | function_call
    {
        $$ = $1;
    }
    | array_access
    {
        $$ = $1;
    }
    ;

function_call
    : IDENTIFIER LPAREN arg_list RPAREN
    {
        $$ = create_node(NODE_FUNCTION_CALL, $1);
        $$->left = $3;
    }
    ;

array_access
    : IDENTIFIER LBRACKET expression RBRACKET
    {
        $$ = create_node(NODE_ARRAY_ACCESS, $1);
        $$->left = $3;
    }
    ;

arg_list
    : args
    {
        $$ = $1;
    }
    | /* empty */
    {
        $$ = NULL;
    }
    ;

args
    : expression
    {
        $$ = $1;
    }
    | args COMMA expression
    {
        ASTNode* temp = $1;
        while(temp->next != NULL) {
            temp = temp->next;
        }
        temp->next = $3;
        $$ = $1;
    }
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", yylineno, s);
}

ASTNode* create_node(NodeType type, char* value) {
    ASTNode* node = malloc(sizeof(ASTNode));
    if (node == NULL) {
        fprintf(stderr, "Memory allocation failed for AST node\n");
        exit(1);
    }
    node->type = type;
    node->value = value;
    node->left = NULL;
    node->right = NULL;
    node->next = NULL;
    return node;
}

void free_ast(ASTNode* node) {
    if (node == NULL) return;
    if (node->left) {
        free_ast(node->left);
        node->left = NULL;
    }
    if (node->right) {
        free_ast(node->right);
        node->right = NULL;
    }
    if (node->next) {
        free_ast(node->next);
        node->next = NULL;
    }
    if (node->value) {
        free(node->value);
        node->value = NULL;
    }
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