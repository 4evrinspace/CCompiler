%{
#include "compiler.h"
#include "parser.tab.h"
#include <string.h>

void yyerror(const char* s);
%}

%option noyywrap
%option yylineno

DIGIT       [0-9]
LETTER      [a-zA-Z]
ID          {LETTER}({LETTER}|{DIGIT})*
NUMBER      {DIGIT}+
WHITESPACE  [ \t\n\r]+
COMMENT     "/\*"([^*]|\*+[^*/])*\*+"/"
LINECOMMENT "//".*\n
STRING      \"[^\"]*\"
CHAR        \'[^\']*\'

%%

"int"       { return INT; }
"char"      { return CHAR; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"for"       { return FOR; }
"return"    { return RETURN; }
"void"      { return VOID; }

"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return TIMES; }
"/"         { return DIVIDE; }
"%"         { return MOD; }
"="         { return ASSIGN; }
"+="        { return PLUS_ASSIGN; }
"-="        { return MINUS_ASSIGN; }
"=="        { return EQ; }
"!="        { return NEQ; }
"<"         { return LT; }
">"         { return GT; }
"<="        { return LE; }
">="        { return GE; }
"&&"        { return AND; }
"||"        { return OR; }
"!"         { return NOT; }

"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
"["         { return LBRACKET; }
"]"         { return RBRACKET; }
";"         { return SEMICOLON; }
","         { return COMMA; }

{ID}        {
    yylval.str = (char*)malloc(strlen(yytext) + 1);
    strcpy(yylval.str, yytext);
    return IDENTIFIER;
}
{NUMBER}    { yylval.num = atoi(yytext); return NUMBER; }
{STRING}    {
    yylval.str = (char*)malloc(strlen(yytext) + 1);
    strcpy(yylval.str, yytext);
    return STRING_LITERAL;
}
{CHAR}      {
    yylval.str = (char*)malloc(strlen(yytext) + 1);
    strcpy(yylval.str, yytext);
    return CHAR_LITERAL;
}
{WHITESPACE} { }
{COMMENT}   { }
{LINECOMMENT} { }

.           {
              fprintf(stderr, "Error at line %d: Invalid character '%s'\n", yylineno, yytext);
              return -1;
            }

%%

#undef yywrap
int yywrap(void) {
    return 1;
}