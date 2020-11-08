%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include "calc.tab.h"

#define YYLMAX 100

extern FILE *yyout;
extern int yylineno;
extern int yylex();
extern void yyerror(const char * s);


%}



%union{
	struct{
		char *lexema;
		int lenght;
		int line;
	}ident;
	int enter;
	float real;
	char caracter;
	char * string;
}

%token <enter> INTEGER
%token <ident> ID
%token <real> REAL
%token ASSIGN POTENCIA MAYOR_QUE MENOR_QUE MAYOR_IGUAL_QUE MENOR_IGUAL_QUE IGUAL_QUE DIFF_DE BOOL_TRUE BOOL_FALSE SUMA RESTA MULTIPLICACION DIVISION MODULO AND NEG OR CADENA



%%

lista_sentencias : expressio | lista_sentencias expressio;

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

void yyerror(const char *explanation){
fprintf(stderr,"Error: %s ,in line %d \n",explanation,yylineno);
}
