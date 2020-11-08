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
%token ASSIGN POTENCIA GT LT GE LE EQ NE BOOL_TRUE BOOL_FALSE SUM REST MUL DIV MOD AND NEG OR FIN_SENTENCIA ABRIR_PAR CERRAR_PAR

%type <expr> expresion operacion_aritm operacion_aritm_base operacion_aritm_prec1 operacion_aritm_prec2

%%


lista_sentencias : sentencia | lista_sentencias sentencia;

sentencia: expresion FIN_SENTENCIA | asignacion FIN_SENTENCIA | asignacion | expresion;

asignacion : ID ASSIGN expresion { $1.value = $3;
				  sym_enter($1.nom, &$1.value);
				  fprintf(yyout,"ID: %s es %s\n",$1.nom, varToString($1.value));}
;

expresion: operacion_aritm | expresion_bool;

operacion_aritm: operacion_aritm_prec1 | 
		operacion_aritm SUM operacion_aritm_prec2 |
		operacion_aritm REST operacion_aritm_prec2 |
		SUM operacion_aritm_prec2 |			
		REST operacion_aritm_prec2
;


operacion_aritm_prec1: 	operacion_aritm_prec2 | 
			operacion_aritm_prec1 MUL operacion_aritm_prec2 |
			operacion_aritm_prec1 DIV operacion_aritm_prec2 |
			operacion_aritm_prec1 MOD operacion_aritm_prec2
;

operacion_aritm_prec2: operacion_aritm_base | operacion_aritm_prec2 POTENCIA operacion_aritm_base;


operacion_aritm_base: ABRIR_PAR operacion_aritm CERRAR_PAR { $$=$2;} |
	   INTEGER { $$.tipo=entero; $$.valor.entero=$1;} |
	   REAL { $$.tipo=real; $$.valor.real=$1;} |
	   CADENA { $$.tipo=cadena; $$.valor.cadena=$1;} |
	   BOOLEAN { $$.tipo=boolean; $$.valor.boolean=$1;} |
	   ID { sym_lookup($1.nom, &$1.value); $$.tipo=$1.value.tipo; $$.valor=$1.value.valor;}
;


expresion_bool: {};


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
