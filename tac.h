#ifndef TAC_H
#define TAC_H

#define MAX_TAC 512

typedef struct {
    char op[8];
    char arg1[16];
    char arg2[16];
    char res[16];
} Quad;

extern Quad tac[MAX_TAC];
extern int tac_count;

char* new_temp();
char* new_label();
void emit_tac(const char *op, const char *a1, const char *a2, const char *res);
void print_tac();
void optimize_constant_folding();
void generate_target_code();

#endif