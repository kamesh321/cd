#include <stdio.h>
#include "tac.h"

extern int yyparse();
extern FILE *yyin;
extern int syntax_errors;

int main() {
    FILE *fp = fopen("input.c", "r");
    if (!fp) {
        perror("Error opening input.c");
        return 1;
    }
    yyin = fp;

    printf("=====================================================\n");
    printf("         PHASE 1: LEXICAL ANALYSIS (SCANNING)        \n");
    printf("=====================================================\n");

    int res = yyparse();
    fclose(fp);

    printf("\n=====================================================\n");
    printf("         PHASE 2: SYNTAX ANALYSIS                    \n");
    printf("=====================================================\n");

    if (res == 0 && syntax_errors == 0) {
        printf("Syntactically correct\n");
    } else {
        printf("Syntax errors found. Compilation aborted.\n");
        return 1;
    }

    printf("\n=====================================================\n");
    printf("         PHASE 4: INTERMEDIATE CODE GENERATION (TAC) \n");
    printf("=====================================================\n");
    print_tac();

    printf("\n=====================================================\n");
    printf("         PHASE 5: CODE OPTIMIZATION (CONSTANT FOLD)  \n");
    printf("=====================================================\n");
    optimize_constant_folding();

    printf("\nOptimized Intermediate Code:\n");
    print_tac();

    printf("\n=====================================================\n");
    printf("         PHASE 6: TARGET CODE GENERATION (8086 ASM)  \n");
    printf("=====================================================\n");
    generate_target_code();

    return 0;
}