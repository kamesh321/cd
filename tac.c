#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "tac.h"

Quad tac[MAX_TAC];
int tac_count = 0;
static int temp_idx = 1;
static int label_idx = 1;

char* new_temp() {
    static char buf[16];
    sprintf(buf, "t%d", temp_idx++);
    return strdup(buf);
}

char* new_label() {
    static char buf[16];
    sprintf(buf, "L%d", label_idx++);
    return strdup(buf);
}

void emit_tac(const char *op, const char *a1, const char *a2, const char *res) {
    if (tac_count >= MAX_TAC) return;
    strncpy(tac[tac_count].op,   op  ? op  : "", 7);
    strncpy(tac[tac_count].arg1, a1  ? a1  : "", 15);
    strncpy(tac[tac_count].arg2, a2  ? a2  : "", 15);
    strncpy(tac[tac_count].res,  res ? res : "", 15);
    tac_count++;
}

void print_tac() {
    for (int i = 0; i < tac_count; i++) {
        Quad *q = &tac[i];
        if (!strcmp(q->op, "LABEL"))         printf("   (%d) %s:\n", i + 1, q->res);
        else if (!strcmp(q->op, "GOTO"))     printf("   (%d) GOTO %s\n", i + 1, q->res);
        else if (!strcmp(q->op, "IF_FALSE")) printf("   (%d) IF_FALSE %s GOTO %s\n", i + 1, q->arg1, q->res);
        else if (!strcmp(q->op, "="))        printf("   (%d) %-6s = %s\n", i + 1, q->res, q->arg1);
        else                                 printf("   (%d) %-6s = %s %s %s\n", i + 1, q->res, q->arg1, q->op, q->arg2);
    }
}

static int is_num(const char *s) {
    if (!s || !*s) return 0;
    for (int i = (s[0] == '-'); s[i]; i++) if (!isdigit(s[i])) return 0;
    return 1;
}

/* Evaluate basic ops table-style */
static int eval_bin(const char *op, int a, int b) {
    if (!strcmp(op, "+"))  return a + b;
    if (!strcmp(op, "-"))  return a - b;
    if (!strcmp(op, "*"))  return a * b;
    if (!strcmp(op, "/"))  return b ? a / b : 0;
    if (!strcmp(op, "<"))  return a < b;
    if (!strcmp(op, ">"))  return a > b;
    if (!strcmp(op, "==")) return a == b;
    if (!strcmp(op, "!=")) return a != b;
    if (!strcmp(op, "<=")) return a <= b;
    if (!strcmp(op, ">=")) return a >= b;
    return 0;
}

void optimize_constant_folding() {
    int folded = 0;
    for (int i = 0; i < tac_count; i++) {
        Quad *q = &tac[i];
        if (is_num(q->arg1) && is_num(q->arg2)) {
            int v = eval_bin(q->op, atoi(q->arg1), atoi(q->arg2));
            printf("   [FOLD] %s = %s %s %s  ==>  %s = %d\n", q->res, q->arg1, q->op, q->arg2, q->res, v);
            strcpy(q->op, "=");
            sprintf(q->arg1, "%d", v);
            q->arg2[0] = '\0';
            folded++;
        }
    }
    if (!folded) printf("   (No constant expressions available to fold)\n");
}

/* Map relational operator to 8086 conditional jump mnemonic */
static const char* get_rel_jmp(const char *op) {
    if (!strcmp(op, "<"))  return "JL";
    if (!strcmp(op, ">"))  return "JG";
    if (!strcmp(op, "==")) return "JE";
    if (!strcmp(op, "!=")) return "JNE";
    if (!strcmp(op, "<=")) return "JLE";
    if (!strcmp(op, ">=")) return "JGE";
    return "JMP";
}

void generate_target_code() {
    for (int i = 0; i < tac_count; i++) {
        Quad *q = &tac[i];
        if (!strcmp(q->op, "LABEL")) {
            printf("%s:\n\n", q->res);
        } else if (!strcmp(q->op, "GOTO")) {
            printf("JMP %s\n\n", q->res);
        } else if (!strcmp(q->op, "IF_FALSE")) {
            printf("MOV AX, %s\nCMP AX, 0\nJE %s\n\n", q->arg1, q->res);
        } else if (!strcmp(q->op, "=")) {
            printf("MOV AX, %s\nMOV %s, AX\n\n", q->arg1, q->res);
        } else if (strchr("+-*/", q->op[0]) && q->op[1] == '\0') {
            printf("MOV AX, %s\n", q->arg1);
            if (q->op[0] == '+')      printf("ADD AX, %s\n", q->arg2);
            else if (q->op[0] == '-') printf("SUB AX, %s\n", q->arg2);
            else if (q->op[0] == '*') printf("MOV BX, %s\nMUL BX\n", q->arg2);
            else if (q->op[0] == '/') printf("MOV BX, %s\nXOR DX, DX\nDIV BX\n", q->arg2);
            printf("MOV %s, AX\n\n", q->res);
        } else {
            /* Relational compare operations */
            char *lt = new_label(), *le = new_label();
            printf("MOV AX, %s\nCMP AX, %s\n%s %s\n", q->arg1, q->arg2, get_rel_jmp(q->op), lt);
            printf("MOV %s, 0\nJMP %s\n%s:\nMOV %s, 1\n%s:\n\n", q->res, le, lt, q->res, le);
            free(lt); free(le);
        }
    }
}