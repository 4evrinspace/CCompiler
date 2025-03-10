%{
#include "compiler.h"
#include "parser.tab.h"

void yyerror(const char* s);
%}

%option noyywrap
%option yylineno

DIGIT       [0-9]
LETTER      [a-zA-Z]
ID          {LETTER}({LETTER}|{DIGIT})*
NUMBER      {DIGIT}+
WHITESPACE  [ \t\n]
COMMENT     "/*"[^*]*"*"+([^*/][^*]*"*"+)*"/"

%%

"int"       { return INT; }
"char"      { return CHAR; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"return"    { return RETURN; }
"void"      { return VOID; }

"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return TIMES; }
"/"         { return DIVIDE; }
"="         { return ASSIGN; }
"=="        { return EQ; }
"!="        { return NEQ; }
"<"         { return LT; }
">"         { return GT; }
"<="        { return LE; }
">="        { return GE; }

"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
";"         { return SEMICOLON; }
","         { return COMMA; }

{ID}        { yylval.str = strdup(yytext); return IDENTIFIER; }
{NUMBER}    { yylval.num = atoi(yytext); return NUMBER; }
{WHITESPACE} { /* ignore whitespace */ }
{COMMENT}   { /* ignore comments */ }

.           { 
              fprintf(stderr, "Error at line %d: Invalid character '%s'\n", yylineno, yytext);
              return -1;
            }

%%

int yywrap() {
    return 1;
}