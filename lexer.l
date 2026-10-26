%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tac.h"
#include "y.tab.h"

void print_token(const char* token, const char* lexeme) {
    printf("   [TOKEN] %-12s : %s\n", token, lexeme);
}
%}

%option noyywrap
%option nounput
%option noinput

DIGIT       [0-9]+
ID          [a-zA-Z_][a-zA-Z0-9_]*

%%

[ \t\r\n]+             ; /* Skip whitespace */

"int"                  { print_token("KEYWORD", yytext); return INT; }
"if"                   { print_token("KEYWORD", yytext); return IF; }
"else"                 { print_token("KEYWORD", yytext); return ELSE; }
"while"                { print_token("KEYWORD", yytext); return WHILE; }
"for"                  { print_token("KEYWORD", yytext); return FOR; }

"<="                   { print_token("REL_OP", yytext); return LE; }
">="                   { print_token("REL_OP", yytext); return GE; }
"=="                   { print_token("REL_OP", yytext); return EQ; }
"!="                   { print_token("REL_OP", yytext); return NE; }
"<"                    { print_token("REL_OP", yytext); return '<'; }
">"                    { print_token("REL_OP", yytext); return '>'; }

{DIGIT}                { print_token("NUMBER", yytext); yylval.str = strdup(yytext); return NUM; }
{ID}                   { print_token("IDENTIFIER", yytext); yylval.str = strdup(yytext); return ID; }

"="                    { print_token("ASSIGN", yytext); return '='; }
"+"                    { print_token("ADD_OP", yytext); return '+'; }
"-"                    { print_token("SUB_OP", yytext); return '-'; }
"*"                    { print_token("MUL_OP", yytext); return '*'; }
"/"                    { print_token("DIV_OP", yytext); return '/'; }
";"                    { print_token("SEMICOLON", yytext); return ';'; }
"("                    { print_token("LPAREN", yytext); return '('; }
")"                    { print_token("RPAREN", yytext); return ')'; }
"{"                    { print_token("LBRACE", yytext); return '{'; }
"}"                    { print_token("RBRACE", yytext); return '}'; }

.                      { printf("   [LEXICAL ERROR] Unrecognized character: '%s'\n", yytext); }

%%