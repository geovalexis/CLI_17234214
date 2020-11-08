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
		char *nom;		
		void *value;
		enum tipus{
			entero, 
			real, 
			cadena, 
			boolean}tipo;
	}variable;
	int entero;
	float real;
	char *str;
	bool boolean;
}

%token <variable> ID
%token <entero> INTEGER 
%token <float> REAL 
%token <str> CADENA 
%token <boolean> BOOLEAN
%token ASSIGN POTENCIA MAYOR_QUE MENOR_QUE MAYOR_IGUAL_QUE MENOR_IGUAL_QUE IGUAL_QUE DIFF_DE BOOL_TRUE BOOL_FALSE SUMA RESTA MULTIPLICACION DIVISION MODULO AND NEG OR



%%

lista_sentencias : expressio | lista_sentencias expressio;

expressio : ID ASSIGN INTEGER {
				fprintf(yyout,"ID: %s pren per valor: %d\n",$<variable>1.nom, $3);
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
