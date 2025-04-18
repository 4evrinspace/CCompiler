%{
#include "compiler.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

/* Starting point for the grammar */
program
    : function_def
    {
        $$ = $1;
        root = $$;
        printf("Created program with function\n");
    }
    | program function_def
    {
        // For multiple functions, add to linked list
        ASTNode* temp = $1;
        while(temp->next != NULL) {
            temp = temp->next;
        }
        temp->next = $2;
        $$ = $1;
        printf("Added function to program\n");
    }
    ;

function_def
    : type IDENTIFIER LPAREN param_list RPAREN LBRACE statements RBRACE
    {
        $$ = create_node(NODE_FUNCTION, $2);
        $$->left = $4;  // parameters
        $$->right = $7; // statements
        printf("Created function: %s\n", $2);
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
        printf("Created parameter: %s\n", $2);
    }
    | params COMMA type IDENTIFIER
    {
        ASTNode* param = create_node(NODE_DECLARATION, $4);
        printf("Created parameter: %s\n", $4);
        
        // Add to end of list
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
        $$ = create_node(NODE_TYPE, strdup("int"));
    }
    | CHAR
    {
        $$ = create_node(NODE_TYPE, strdup("char"));
    }
    | VOID
    {
        $$ = create_node(NODE_TYPE, strdup("void"));
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
            // Add to end of list
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
        printf("Created variable declaration: %s\n", $2);
    }
    | type IDENTIFIER ASSIGN expression
    {
        $$ = create_node(NODE_DECLARATION, $2);
        $$->right = $4;
        printf("Created initialized variable: %s\n", $2);
    }
    | type IDENTIFIER LBRACKET NUMBER RBRACKET
    {
        // For array declaration, store the size in the node value
        char* array_info = malloc(strlen($2) + 20);
        sprintf(array_info, "%s[%d]", $2, $4);
        $$ = create_node(NODE_DECLARATION, array_info);
        printf("Created array declaration: %s[%d]\n", $2, $4);
    }
    ;

if_statement
    : IF LPAREN expression RPAREN statement
    {
        $$ = create_node(NODE_IF, NULL);
        $$->left = $3;  // condition
        $$->right = $5; // if body
        printf("Created if statement\n");
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        // Create if node
        $$ = create_node(NODE_IF, NULL);
        $$->left = $3;  // condition
        $$->right = $5; // if body
        
        // Create else node and chain it
        ASTNode* else_node = create_node(NODE_ELSE, NULL);
        else_node->right = $7; // else body
        
        // Link else to if
        $$->next = else_node;
        printf("Created if-else statement\n");
    }
    ;

while_statement
    : WHILE LPAREN expression RPAREN statement
    {
        $$ = create_node(NODE_WHILE, NULL);
        $$->left = $3;  // condition
        $$->right = $5; // body
        printf("Created while loop\n");
    }
    ;

for_statement
    : FOR LPAREN expression SEMICOLON expression SEMICOLON expression RPAREN statement
    {
        $$ = create_node(NODE_FOR, NULL);
        
        // Create compound init-condition-iteration node
        $$->left = $3;  // initialization
        $$->right = $5; // condition
        
        // Chain iteration to condition and body to iteration
        $5->next = $7;  // iteration
        $7->next = $9;  // body
        
        printf("Created for loop\n");
    }
    ;

return_statement
    : RETURN expression SEMICOLON
    {
        $$ = create_node(NODE_RETURN, NULL);
        $$->left = $2;
        printf("Created return statement\n");
    }
    | RETURN SEMICOLON
    {
        $$ = create_node(NODE_RETURN, NULL);
        printf("Created void return statement\n");
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
        printf("Created assignment: %s\n", $1);
    }
    | IDENTIFIER PLUS_ASSIGN assignment_expr
    {
        // Create a combined + and = operation
        ASTNode* plus = create_node(NODE_EXPRESSION, strdup("+"));
        plus->left = create_node(NODE_EXPRESSION, $1);
        plus->right = $3;
        
        $$ = create_node(NODE_ASSIGNMENT, $1);
        $$->right = plus;
        printf("Created compound assignment: %s += ...\n", $1);
    }
    | IDENTIFIER MINUS_ASSIGN assignment_expr
    {
        // Create a combined - and = operation
        ASTNode* minus = create_node(NODE_EXPRESSION, strdup("-"));
        minus->left = create_node(NODE_EXPRESSION, $1);
        minus->right = $3;
        
        $$ = create_node(NODE_ASSIGNMENT, $1);
        $$->right = minus;
        printf("Created compound assignment: %s -= ...\n", $1);
    }
    | array_access ASSIGN assignment_expr
    {
        // Assignment to array element
        $$ = create_node(NODE_ASSIGNMENT, NULL);
        $$->left = $1;   // array access
        $$->right = $3;  // value to assign
        printf("Created array assignment\n");
    }
    ;

logical_expr
    : relational_expr
    {
        $$ = $1;
    }
    | logical_expr AND relational_expr
    {
        $$ = create_node(NODE_EXPRESSION, strdup("&&"));
        $$->left = $1;
        $$->right = $3;
        printf("Created logical AND\n");
    }
    | logical_expr OR relational_expr
    {
        $$ = create_node(NODE_EXPRESSION, strdup("||"));
        $$->left = $1;
        $$->right = $3;
        printf("Created logical OR\n");
    }
    ;

relational_expr
    : additive_expr
    {
        $$ = $1;
    }
    | relational_expr EQ additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, strdup("=="));
        $$->left = $1;
        $$->right = $3;
        printf("Created equality comparison\n");
    }
    | relational_expr NEQ additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, strdup("!="));
        $$->left = $1;
        $$->right = $3;
        printf("Created inequality comparison\n");
    }
    | relational_expr LT additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, strdup("<"));
        $$->left = $1;
        $$->right = $3;
        printf("Created less-than comparison\n");
    }
    | relational_expr GT additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, strdup(">"));
        $$->left = $1;
        $$->right = $3;
        printf("Created greater-than comparison\n");
    }
    | relational_expr LE additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, strdup("<="));
        $$->left = $1;
        $$->right = $3;
        printf("Created less-than-equal comparison\n");
    }
    | relational_expr GE additive_expr
    {
        $$ = create_node(NODE_EXPRESSION, strdup(">="));
        $$->left = $1;
        $$->right = $3;
        printf("Created greater-than-equal comparison\n");
    }
    ;

additive_expr
    : term
    {
        $$ = $1;
    }
    | additive_expr PLUS term
    {
        $$ = create_node(NODE_EXPRESSION, strdup("+"));
        $$->left = $1;
        $$->right = $3;
        printf("Created addition\n");
    }
    | additive_expr MINUS term
    {
        $$ = create_node(NODE_EXPRESSION, strdup("-"));
        $$->left = $1;
        $$->right = $3;
        printf("Created subtraction\n");
    }
    ;

term
    : factor
    {
        $$ = $1;
    }
    | term TIMES factor
    {
        $$ = create_node(NODE_EXPRESSION, strdup("*"));
        $$->left = $1;
        $$->right = $3;
        printf("Created multiplication\n");
    }
    | term DIVIDE factor
    {
        $$ = create_node(NODE_EXPRESSION, strdup("/"));
        $$->left = $1;
        $$->right = $3;
        printf("Created division\n");
    }
    | term MOD factor
    {
        $$ = create_node(NODE_EXPRESSION, strdup("%"));
        $$->left = $1;
        $$->right = $3;
        printf("Created modulo\n");
    }
    ;

factor
    : IDENTIFIER
    {
        $$ = create_node(NODE_EXPRESSION, $1);
        printf("Created identifier reference: %s\n", $1);
    }
    | NUMBER
    {
        char buffer[20];
        sprintf(buffer, "%d", $1);
        $$ = create_node(NODE_EXPRESSION, strdup(buffer));
        printf("Created number: %d\n", $1);
    }
    | STRING_LITERAL
    {
        $$ = create_node(NODE_STRING, $1);
        printf("Created string literal\n");
    }
    | CHAR_LITERAL
    {
        $$ = create_node(NODE_CHAR, $1);
        printf("Created char literal\n");
    }
    | LPAREN expression RPAREN
    {
        $$ = $2;
    }
    | NOT factor
    {
        $$ = create_node(NODE_EXPRESSION, strdup("!"));
        $$->right = $2;
        printf("Created logical NOT\n");
    }
    | MINUS factor
    {
        $$ = create_node(NODE_EXPRESSION, strdup("-"));
        $$->right = $2;
        printf("Created unary minus\n");
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
        printf("Created function call: %s\n", $1);
    }
    ;

array_access
    : IDENTIFIER LBRACKET expression RBRACKET
    {
        $$ = create_node(NODE_ARRAY_ACCESS, $1);
        $$->left = $3; // index
        printf("Created array access: %s[...]\n", $1);
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
        // Chain arguments together
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

char* my_strdup(const char* s) {
    char* result = malloc(strlen(s) + 1);
    if (result == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(1);
    }
    strcpy(result, s);
    return result;
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