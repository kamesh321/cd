Change input.c  
Code optimization technique: Constant Folding 


Run Commands
yacc -d parser.y 
lex lexer.l 
gcc -Wall -o mini main.c y.tab.c lex.yy.c tac.c 
./mini

