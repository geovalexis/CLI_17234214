%{

#include <stdio.h>
#include <stdlib.h>
#include "exemple7y.h"

#define YYLMAX 100

extern FILE *yyout;
extern int yylineno;
extern int yylex();
/*extern void yyerror(char*);*/
%}

%union{
	struct{
		char *lexema;
		int lenght;
		int line;
	}ident;
	int enter;
	void *no_definit;
}

%token <no_definit> ASSIGN
%token <enter> INTEGER
%token <ident> ID

%type <no_definit> expressio

%%

expressio : ID ASSIGN INTEGER {
				fprintf(yyout,"ID: %s pren per valor: %d\n",$<ident>1.lexema, $<enter>3);
				}

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
