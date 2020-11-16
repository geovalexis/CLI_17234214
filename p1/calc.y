%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include "calc.tab.h"

#define YYLMAX 100

extern FILE *yyout;
extern int yylineno;
extern int yylex();
extern void yyerror(const char * s);
char* varToString(sym_value_type var);
void printExpr(sym_value_type expr);
void concatenarCadenas(sym_value_type s1, sym_value_type s2, char* buffer);

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

%token <variable> ID_ARITM ID_BOOL
%token <entero> INTEGER 
%token <real> REAL 
%token <str> CADENA
%token <boolean> BOOLEAN
%token ASSIGN POTENCIA GT LT GE LE EQ NE BOOL_TRUE BOOL_FALSE SUM REST MUL DIV MOD AND NEG OR FIN_SENTENCIA ABRIR_PAR CERRAR_PAR

%type <expr> expresion expresion_aritmetica expresion_bool operacion_aritm_base operacion_aritm_prec1 operacion_aritm_prec2

%type <variable> id

%%


lista_sentencias : lista_sentencias sentencia | sentencia;

sentencia:  FIN_SENTENCIA | expresion FIN_SENTENCIA {printExpr($1);} | asignacion FIN_SENTENCIA;

asignacion : id ASSIGN expresion { $1.value = $3;
				  sym_enter($1.nom, &$1.value);
				  fprintf(yyout,"ID: %s es %s\n",$1.nom, varToString($1.value));}
;

id: ID_BOOL | ID_ARITM;

expresion: expresion_aritmetica | expresion_bool;

expresion_aritmetica: operacion_aritm_prec1 | 
		expresion_aritmetica SUM operacion_aritm_prec1 {
		if ($1.tipo!=2 && $3.tipo!=2) {
			if ($1.tipo==$3.tipo){
				$$.tipo=$1.tipo;
				if ($1.tipo==0) $$.valor.entero=$1.valor.entero + $3.valor.entero;
				else if ($1.tipo==1) $$.valor.real=$1.valor.real + $3.valor.real;
				else $$.tipo=-1;
			}
			else if ($1.tipo==1 || $3.tipo==1){
				$$.tipo = 1;
				if ($1.tipo==1) $$.valor.real=$1.valor.real + (float)$3.valor.entero;
				else if ($3.tipo==1) $$.valor.real=(float)$1.valor.entero + $3.valor.real;
				else $$.tipo=-1;
			}
			else $$.tipo=-1;
		}
		else {
			$$.tipo=3;
			concatenarCadenas($1, $3, $$.valor.cadena);
		}				

}|
		expresion_aritmetica REST operacion_aritm_prec1 {
		if ($1.tipo==$3.tipo){
			$$.tipo=$1.tipo;
			if ($1.tipo==0) $$.valor.entero=$1.valor.entero - $3.valor.entero;
			else if ($1.tipo==1) $$.valor.real=$1.valor.real - $3.valor.real;
			else $$.tipo=-1;
		}
		else if ($1.tipo==1 || $3.tipo==1){
			$$.tipo = 1;
			if ($1.tipo==1) $$.valor.real=$1.valor.real - (float)$3.valor.entero;
			else if ($3.tipo==1) $$.valor.real=(float) $1.valor.entero - $3.valor.real;
			else $$.tipo=-1;
		}
		else $$.tipo=-1;
}|
		SUM operacion_aritm_prec1 {$$=$2;}|			
		REST operacion_aritm_prec1 {
		$$.tipo = $2.tipo;
		if ($2.tipo==0) $$.valor.entero = $2.valor.entero * (-1);
		else $$.valor.real = $2.valor.real * (-1);
}
;


operacion_aritm_prec1: 	operacion_aritm_prec2 | 
		operacion_aritm_prec1 MUL operacion_aritm_prec2 {
		if ($1.tipo==$3.tipo){
			$$.tipo=$1.tipo;
			if ($1.tipo==0) $$.valor.entero=$1.valor.entero * $3.valor.entero;
			else if ($1.tipo==1) $$.valor.real=$1.valor.real * $3.valor.real;
			else $$.tipo=-1;
		}
		else if ($1.tipo==1 || $3.tipo==1){
			$$.tipo = 1;
			if ($1.tipo==1) $$.valor.real=$1.valor.real * (float)$3.valor.entero;
			else if ($3.tipo==1) $$.valor.real=(float) $1.valor.entero * $3.valor.real;
			else $$.tipo=-1;
		}
		else $$.tipo=-1;
}|
		operacion_aritm_prec1 DIV operacion_aritm_prec2 {
		if (($3.tipo==0 && $3.valor.entero==0) || ($3.tipo==1 && $3.valor.real==0)){
			yyerror("No se puede dividir entre 0");
		}	
		else {	
			if ($1.tipo==$3.tipo){
				$$.tipo=$1.tipo;
				if ($1.tipo==0) $$.valor.entero=$1.valor.entero / $3.valor.entero;
				else if ($1.tipo==1) $$.valor.real=$1.valor.real / $3.valor.real;
				else $$.tipo=-1;
			}
			else if ($1.tipo==1 || $3.tipo==1){
				$$.tipo = 1;
				if ($1.tipo==1) $$.valor.real=$1.valor.real / (float)$3.valor.entero;
				else if ($3.tipo==1) $$.valor.real=(float) $1.valor.entero / $3.valor.real;
				else $$.tipo=-1;
			}
			else $$.tipo=-1;
		}
}|
		operacion_aritm_prec1 MOD operacion_aritm_prec2 {
		if ($1.tipo==0 && $3.tipo==0){
			$$.tipo=0;
			$$.valor.entero=$1.valor.entero % $3.valor.entero;
		}
		else $$.tipo=-1;
}
;

operacion_aritm_prec2: operacion_aritm_base | operacion_aritm_prec2 POTENCIA operacion_aritm_base {
		if ($1.tipo==$3.tipo){
			$$.tipo=$1.tipo;
			if ($1.tipo==0) $$.valor.entero=(int)pow($1.valor.entero, $3.valor.entero);
			else if ($1.tipo==1) $$.valor.real=pow($1.valor.real, $3.valor.real);
			else $$.tipo=-1;
		}
		else if ($1.tipo==1 || $3.tipo==1){
			$$.tipo = 1;
			if ($1.tipo==1) $$.valor.real=pow($1.valor.real, (float)$3.valor.entero);
			else if ($3.tipo==1) $$.valor.real=pow((float) $1.valor.entero, $3.valor.real);
			else $$.tipo=-1;
		}
		else $$.tipo=-1;		


};


operacion_aritm_base: ABRIR_PAR expresion_aritmetica CERRAR_PAR { $$=$2;} |
	   INTEGER { $$.tipo=entero; $$.valor.entero=$1;}|
	   REAL { $$.tipo=real; $$.valor.real=$1;} |
	   CADENA { $$.tipo=cadena; $$.valor.cadena=$1;} |
	   BOOLEAN { $$.tipo=boolean; $$.valor.boolean=$1;} |
	   ID_ARITM { sym_lookup($1.nom, &$1.value); $$.tipo=$1.value.tipo; $$.valor=$1.value.valor;}
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
	default: sprintf(buffer, "Type not found");
   }
   return buffer;
}


void printExpr(sym_value_type expr){

	fprintf(yyout,"EXPRESION: expresion que contiene %s\n", varToString(expr));

}

void concatenarCadenas(sym_value_type s1, sym_value_type s2, char* buffer){
	buffer = malloc(sizeof(char)*512); /*Podrá contener ints o reales*/	
	if ((s1.tipo==2) && (s2.tipo==2)){
		snprintf(buffer, sizeof buffer, "%s%s", s1, s2);
	}
	else if (s1.tipo==2){
		if (s2.tipo==0){
			snprintf(buffer, sizeof buffer, "%s%d", s1, s2);
		}
		else if (s2.tipo==1){
			snprintf(buffer, sizeof buffer, "%s%.3f", s1, s2);
		}
	}
	else if (s2.tipo==2){
		if (s1.tipo==0){
			snprintf(buffer, sizeof buffer, "%d%s", s1, s2);
		}
		else if (s1.tipo==1){
			snprintf(buffer, sizeof buffer, "%.3f%s", s1, s2);
		}
	}
	else snprintf(buffer, sizeof buffer, "No se ha podido concatenar");
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
