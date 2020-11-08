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
char* varToString(sym_value_type var);


%}

%code requires {
	#include "symtab.h"
}


%union{
	struct{
		char *nom;		
		sym_value_type value;
	}variable;
	sym_value_type expr;
	int entero;
	float real;
	char *str;
	bool boolean;
}

%token <variable> ID
%token <entero> INTEGER 
%token <real> REAL 
%token <str> CADENA
%token <boolean> BOOLEAN
%token ASSIGN POTENCIA MAYOR_QUE MENOR_QUE MAYOR_IGUAL_QUE MENOR_IGUAL_QUE IGUAL_QUE DIFF_DE BOOL_TRUE BOOL_FALSE SUMA RESTA MULTIPLICACION DIVISION MODULO AND NEG OR

%type <expr> expresion

%%


lista_sentencias : sentencia | lista_sentencias sentencia;

sentencia: expresion_aritm | expresion_bool | asignacion;

asignacion : ID ASSIGN expresion { $1.value = $3;
				  sym_enter($1.nom, &$1.value);
				  fprintf(yyout,"ID: %s es %s\n",$1.nom, varToString($1.value));
}
;

expresion: INTEGER { $$.tipo=entero; $$.valor.entero=$1;} |
	   REAL { $$.tipo=real; $$.valor.real=$1;} |
	   CADENA { $$.tipo=cadena; $$.valor.cadena=$1;} |
	   BOOLEAN { $$.tipo=boolean; $$.valor.boolean=$1;}
;

expresion_aritm: SUMA;

expresion_bool: BOOLEAN;


%%

char* varToString(sym_value_type var){
   char *buffer = malloc(sizeof(char)*100);
   switch (var.tipo) 
   {
	case 0: sprintf(buffer, "un entero con valor %d", var.valor.entero); break;
	case 1: sprintf(buffer, "un real con valor %.3f", var.valor.real); break;
	case 2: sprintf(buffer, "una cadena con valor %s", var.valor.cadena); break;
	case 3: sprintf(buffer, "un booleano con valor %s", var.valor.boolean ? "true" : "false");break;
	default: sprintf(buffer, "not found");
   }
   return buffer;
}


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
