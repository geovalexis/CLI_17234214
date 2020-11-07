%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "calc.tab.h"

#define YYLMAX 100

extern FILE *yyout;
extern int yylineno;
extern int yylex();
extern void yyerror(char*);
%}

 /*DECLARATIONS*/

%%

 /*RULES*/

%%

int init_analisi_sintactic(char* filename){

int error = EXIT_SUCCESS;

yyout = fopen(filename,"w");

if (yyout == NULL){

error = EXIT_FAILURE;

}

return error;

}

int analisi_semantic(){
int error;

 if (yyparse() == 0)
 {
 error =  EXIT_SUCCESS;
 } else {
 error =  EXIT_FAILURE;
 }

 return error;

}

int end_analisi_sintactic(){

int error;

error = fclose(yyout);

if(error == 0){
 error = EXIT_SUCCESS;
}else{
 error = EXIT_FAILURE;
}

return error;

}

void yyerror(char *explanation){
fprintf(stderr,"Error: %s ,in line %d \n",explanation,yylineno);
}
