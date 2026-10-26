%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tac.h"

extern int yylex();
void yyerror(const char *s);
int syntax_errors = 0;

/* Helper to compress binary op rules into one clean call */
static char* emit_bin(const char *op, char *l, char *r) {
    char *temp = new_temp();
    emit_tac(op, l, r, temp);
    free(l);
    free(r);
    return temp;
}
%}

%union {
    char *str;
    struct {
        char *l_false;
        char *l_exit;
    } if_lbl;
    struct {
        char *l_start;
        char *l_exit;
    } while_lbl;
    struct {
        char *l_cond;
        char *l_step;
        char *l_body;
        char *l_exit;
    } for_lbl;
}

%token INT IF ELSE WHILE FOR
%token LE GE EQ NE
%token <str> ID NUM
%type <str> expr opt_expr
%type <if_lbl> if_prefix
%type <while_lbl> while_prefix while_start
%type <for_lbl> for_prefix for_init

/* Dangling-else ambiguity resolution */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

/* Operator precedence and associativity (lowest to highest) */
%left EQ NE
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/'

%%

program:
    stmt_list {
        if (syntax_errors == 0) printf("\nSyntactically correct\n");
    }
    ;

stmt_list:
    stmt stmt_list
    | /* empty */
    ;

stmt:
    INT ID ';'                      { free($2); }
    | assign_expr ';'
    | ';'                           /* Empty statement */
    | '{' stmt_list '}'
    | if_prefix stmt %prec LOWER_THAN_ELSE {
        emit_tac("LABEL", "", "", $1.l_false);
        free($1.l_false);
        free($1.l_exit);
    }
    | if_prefix stmt ELSE {
        emit_tac("GOTO", "", "", $1.l_exit);
        emit_tac("LABEL", "", "", $1.l_false);
    } stmt {
        emit_tac("LABEL", "", "", $1.l_exit);
        free($1.l_false);
        free($1.l_exit);
    }
    | while_prefix stmt {
        emit_tac("GOTO", "", "", $1.l_start);
        emit_tac("LABEL", "", "", $1.l_exit);
        free($1.l_start);
        free($1.l_exit);
    }
    | for_prefix stmt {
        emit_tac("GOTO", "", "", $1.l_step);
        emit_tac("LABEL", "", "", $1.l_exit);
        free($1.l_cond);
        free($1.l_step);
        free($1.l_body);
        free($1.l_exit);
    }
    ;

assign_expr:
    ID '=' expr {
        emit_tac("=", $3, "", $1);
        free($1);
        free($3);
    }
    ;

opt_expr:
    assign_expr     { $$ = NULL; }
    | expr          { free($1); $$ = NULL; }
    | /* empty */   { $$ = NULL; }
    ;

/* --- IF STATEMENT PREFIX --- */
if_prefix:
    IF '(' expr ')' {
        $$.l_false = new_label();
        $$.l_exit = new_label();
        emit_tac("IF_FALSE", $3, "", $$.l_false);
        free($3);
    }
    ;

/* --- WHILE LOOP (Explicit Helper Non-Terminal) --- */
while_start:
    WHILE {
        $$.l_start = new_label();
        $$.l_exit = new_label();
        emit_tac("LABEL", "", "", $$.l_start);
    }
    ;

while_prefix:
    while_start '(' expr ')' {
        emit_tac("IF_FALSE", $3, "", $1.l_exit);
        free($3);
        $$ = $1;
    }
    ;

/* --- FOR LOOP (Explicit Helper Non-Terminal) --- */
for_init:
    FOR '(' opt_expr ';' {
        $$.l_cond = new_label();
        $$.l_step = new_label();
        $$.l_body = new_label();
        $$.l_exit = new_label();
        emit_tac("LABEL", "", "", $$.l_cond);
    }
    ;

for_prefix:
    for_init expr ';' {
        emit_tac("IF_FALSE", $2, "", $1.l_exit);
        free($2);
        emit_tac("GOTO", "", "", $1.l_body);
        emit_tac("LABEL", "", "", $1.l_step);
    } opt_expr ')' {
        emit_tac("GOTO", "", "", $1.l_cond);
        emit_tac("LABEL", "", "", $1.l_body);
        $$ = $1;
    }
    ;

/* --- EXPRESSIONS --- */
expr:
    expr '+' expr   { $$ = emit_bin("+",  $1, $3); }
    | expr '-' expr { $$ = emit_bin("-",  $1, $3); }
    | expr '*' expr { $$ = emit_bin("*",  $1, $3); }
    | expr '/' expr { $$ = emit_bin("/",  $1, $3); }
    | expr '<' expr { $$ = emit_bin("<",  $1, $3); }
    | expr '>' expr { $$ = emit_bin(">",  $1, $3); }
    | expr EQ expr  { $$ = emit_bin("==", $1, $3); }
    | expr NE expr  { $$ = emit_bin("!=", $1, $3); }
    | expr LE expr  { $$ = emit_bin("<=", $1, $3); }
    | expr GE expr  { $$ = emit_bin(">=", $1, $3); }
    | '(' expr ')'  { $$ = $2; }
    | ID            { $$ = $1; }
    | NUM           { $$ = $1; }
    ;

%%

void yyerror(const char *s) {
    syntax_errors++;
    fprintf(stderr, "Syntax Error: %s\n", s);
}