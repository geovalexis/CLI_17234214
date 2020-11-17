%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <string.h>
#include "calc.tab.h"
#define YYLMAX 100

extern FILE *yyout;
extern int yylineno;
extern int yylex();
extern void yyerror(const char * s);
char* varToString(sym_value_type var);
void printExpr(sym_value_type expr);
char* concatenarCadenas(sym_value_type s1, sym_value_type s2);

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

%token <variable> ID ID_ARITM ID_BOOL
%token <entero> INTEGER 
%token <real> REAL 
%token <str> CADENA
%token <boolean> BOOLEAN
%token ASSIGN POTENCIA GT LT GE LE EQ NE BOOL_TRUE BOOL_FALSE SUM REST MUL DIV MOD AND NEG OR FIN_SENTENCIA ABRIR_PAR CERRAR_PAR

%type <expr> expresion expresion_aritmetica  operacion_aritm_base operacion_aritm_prec1 operacion_aritm_prec2 expresion_bool operacion_boolean_con_aritm operacion_boolean_prec1 operacion_boolean_prec2 operacion_boolean_base


%%


lista_sentencias : lista_sentencias sentencia | sentencia;

sentencia:  FIN_SENTENCIA | expresion FIN_SENTENCIA {printExpr($1);} | asignacion FIN_SENTENCIA;

asignacion : ID ASSIGN expresion { $1.value = $3;
				  sym_enter($1.nom, &$1.value);
				  fprintf(yyout,"ID: %s es %s\n",$1.nom, varToString($1.value));}
;


expresion: expresion_aritmetica | expresion_bool;

expresion_aritmetica: operacion_aritm_prec1 | 
		expresion_aritmetica SUM operacion_aritm_prec1 {
		if ($1.tipo!=cadena&& $3.tipo!=2) {
			if ($1.tipo==$3.tipo){
				$$.tipo=$1.tipo;
				if ($1.tipo==entero) $$.valor.entero=$1.valor.entero + $3.valor.entero;
				else if ($1.tipo==real) $$.valor.real=$1.valor.real + $3.valor.real;
				else $$.tipo=-1;
			}
			else if ($1.tipo==real || $3.tipo==real){
				$$.tipo =real;
				if ($1.tipo==real) $$.valor.real=$1.valor.real + (float)$3.valor.entero;
				else if ($3.tipo==real) $$.valor.real=(float)$1.valor.entero + $3.valor.real;
				else $$.tipo=-1;
			}
			else $$.tipo=-1;
		}
		else {
			$$.tipo=cadena;
			$$.valor.cadena = concatenarCadenas($1, $3);
		}				

}|
		expresion_aritmetica REST operacion_aritm_prec1 {
		if ($1.tipo==$3.tipo){
			$$.tipo=$1.tipo;
			if ($1.tipo==entero) $$.valor.entero=$1.valor.entero - $3.valor.entero;
			else if ($1.tipo==real) $$.valor.real=$1.valor.real - $3.valor.real;
			else $$.tipo=-1;
		}
		else if ($1.tipo==real || $3.tipo==real){
			$$.tipo =real;
			if ($1.tipo==real) $$.valor.real=$1.valor.real - (float)$3.valor.entero;
			else if ($3.tipo==real) $$.valor.real=(float) $1.valor.entero - $3.valor.real;
			else $$.tipo=-1;
		}
		else $$.tipo=-1;
}|
		SUM operacion_aritm_prec1 {$$=$2;}|			
		REST operacion_aritm_prec1 {
		$$.tipo = $2.tipo;
		if ($2.tipo==entero) $$.valor.entero = $2.valor.entero * (-1);
		else $$.valor.real = $2.valor.real * (-1);
}
;


operacion_aritm_prec1: 	operacion_aritm_prec2 | 
		operacion_aritm_prec1 MUL operacion_aritm_prec2 {
		if ($1.tipo==$3.tipo){
			$$.tipo=$1.tipo;
			if ($1.tipo==entero) $$.valor.entero=$1.valor.entero * $3.valor.entero;
			else if ($1.tipo==real) $$.valor.real=$1.valor.real * $3.valor.real;
			else $$.tipo=-1;
		}
		else if ($1.tipo==real || $3.tipo==real){
			$$.tipo =real;
			if ($1.tipo==real) $$.valor.real=$1.valor.real * (float)$3.valor.entero;
			else if ($3.tipo==real) $$.valor.real=(float) $1.valor.entero * $3.valor.real;
			else $$.tipo=-1;
		}
		else $$.tipo=-1;
}|
		operacion_aritm_prec1 DIV operacion_aritm_prec2 {
		if (($3.tipo==entero && $3.valor.entero==entero) || ($3.tipo==real && $3.valor.real==entero)){
			yyerror("No se puede dividir entre 0");
		}	
		else {	
			if ($1.tipo==$3.tipo){
				$$.tipo=$1.tipo;
				if ($1.tipo==entero) $$.valor.entero=$1.valor.entero / $3.valor.entero;
				else if ($1.tipo==real) $$.valor.real=$1.valor.real / $3.valor.real;
				else $$.tipo=-1;
			}
			else if ($1.tipo==real || $3.tipo==real){
				$$.tipo =real;
				if ($1.tipo==real) $$.valor.real=$1.valor.real / (float)$3.valor.entero;
				else if ($3.tipo==real) $$.valor.real=(float) $1.valor.entero / $3.valor.real;
				else $$.tipo=-1;
			}
			else $$.tipo=-1;
		}
}|
		operacion_aritm_prec1 MOD operacion_aritm_prec2 {
		if ($1.tipo==entero && $3.tipo==entero){
			$$.tipo=entero;
			$$.valor.entero=$1.valor.entero % $3.valor.entero;
		}
		else $$.tipo=-1;
}
;

operacion_aritm_prec2: operacion_aritm_base | operacion_aritm_prec2 POTENCIA operacion_aritm_base {
		if ($1.tipo==$3.tipo){
			$$.tipo=$1.tipo;
			if ($1.tipo==entero) $$.valor.entero=(int)pow($1.valor.entero, $3.valor.entero);
			else if ($1.tipo==real) $$.valor.real=pow($1.valor.real, $3.valor.real);
			else $$.tipo=-1;
		}
		else if ($1.tipo==real || $3.tipo==real){
			$$.tipo =real;
			if ($1.tipo==real) $$.valor.real=pow($1.valor.real, (float)$3.valor.entero);
			else if ($3.tipo==real) $$.valor.real=pow((float) $1.valor.entero, $3.valor.real);
			else $$.tipo=-1;
		}
		else $$.tipo=-1;		


};


operacion_aritm_base: ABRIR_PAR expresion_aritmetica CERRAR_PAR { $$=$2;} |
	   INTEGER { $$.tipo=entero; $$.valor.entero=$1;}|
	   REAL { $$.tipo=real; $$.valor.real=$1;} |
	   CADENA { $$.tipo=cadena; $$.valor.cadena=$1;}|
	   ID_ARITM {sym_lookup($1.nom, &$1.value); $$.tipo=$1.value.tipo; $$.valor=$1.value.valor;}
;


expresion_bool: operacion_boolean_prec1 | 
		expresion_bool OR operacion_boolean_prec1 {
		$$.tipo=boolean;
		$$.valor.boolean = $1.valor.boolean || $3.valor.boolean;
}; 

operacion_boolean_prec1: operacion_boolean_prec2 |
		operacion_boolean_prec1 AND operacion_boolean_prec2 {
		$$.tipo=boolean;
		$$.valor.boolean = $1.valor.boolean && $3.valor.boolean;
}; 

operacion_boolean_prec2: operacion_boolean_base | 
		NEG operacion_boolean_prec2 {
		$$.tipo=boolean;
		$$.valor.boolean = !($2.valor.boolean);
}; 

operacion_boolean_base: ABRIR_PAR expresion_bool CERRAR_PAR { $$=$2;} | operacion_boolean_con_aritm |
	   BOOLEAN { $$.tipo=boolean; $$.valor.boolean=$1;} |
	   ID_BOOL { sym_lookup($1.nom, &$1.value); $$.tipo=$1.value.tipo; $$.valor=$1.value.valor;}
;


operacion_boolean_con_aritm: expresion_aritmetica GT expresion_aritmetica {
		$$.tipo =boolean;		
		if (($1.tipo==entero) && ($3.tipo==entero)) $$.valor.boolean = $1.valor.entero > $3.valor.entero;
		else if (($1.tipo==real) && ($3.tipo==real)) $$.valor.boolean = $1.valor.real > $3.valor.real;
		else if (($1.tipo==entero) && ($3.tipo==real)) $$.valor.boolean = $1.valor.entero > $3.valor.real;
		else if (($1.tipo==real) && ($3.tipo==entero)) $$.valor.boolean = $1.valor.real > $3.valor.entero;
		else yyerror("Solo se puede realizar operaciones booleanas sobre enteros y reales"); 
}|
		expresion_aritmetica LT expresion_aritmetica {		
		$$.tipo =boolean;		
		if (($1.tipo==entero) && ($3.tipo==entero)) $$.valor.boolean = $1.valor.entero < $3.valor.entero;
		else if (($1.tipo==real) && ($3.tipo==real)) $$.valor.boolean = $1.valor.real < $3.valor.real;
		else if (($1.tipo==entero) && ($3.tipo==real)) $$.valor.boolean = $1.valor.entero < $3.valor.real;
		else if (($1.tipo==real) && ($3.tipo==entero)) $$.valor.boolean = $1.valor.real < $3.valor.entero;
		else yyerror("Solo se puede realizar operaciones booleanas sobre enteros y reales"); 
}|
		expresion_aritmetica GE expresion_aritmetica {		
		$$.tipo =boolean;
		if (($1.tipo==entero) && ($3.tipo==entero))$$.valor.boolean = ($1.valor.entero > $3.valor.entero ) || ($1.valor.entero == $3.valor.entero );
		else if (($1.tipo==real) && ($3.tipo==real)) $$.valor.boolean = ($1.valor.real > $3.valor.real) || ($1.valor.real == $3.valor.real);
		else if (($1.tipo==entero) && ($3.tipo==real)) $$.valor.boolean = ($1.valor.entero > $3.valor.real ) || ($1.valor.entero == $3.valor.real );
		else if (($1.tipo==real) && ($3.tipo==entero)) $$.valor.boolean = ($1.valor.entero > $3.valor.real) || ($1.valor.entero == $3.valor.real);
		else yyerror("Solo se puede realizar operaciones booleanas sobre enteros o reales"); 
}|
		expresion_aritmetica LE expresion_aritmetica {		
		$$.tipo =boolean;
		if (($1.tipo==entero) && ($3.tipo==entero))$$.valor.boolean = ($1.valor.entero < $3.valor.entero ) || ($1.valor.entero == $3.valor.entero );
		else if (($1.tipo==real) && ($3.tipo==real)) $$.valor.boolean = ($1.valor.real < $3.valor.real) || ($1.valor.real == $3.valor.real);
		else if (($1.tipo==entero) && ($3.tipo==real)) $$.valor.boolean = ($1.valor.entero < $3.valor.real ) || ($1.valor.entero == $3.valor.real );
		else if (($1.tipo==real) && ($3.tipo==entero)) $$.valor.boolean = ($1.valor.entero < $3.valor.real) || ($1.valor.entero == $3.valor.real);
		else yyerror("Solo se puede realizar operaciones booleanas sobre enteros o reales"); 
}|
		expresion_aritmetica EQ expresion_aritmetica {		
		$$.tipo =boolean;		
		if (($1.tipo==entero) && ($3.tipo==entero)) $$.valor.boolean = $1.valor.entero == $3.valor.entero;
		else if (($1.tipo==real) && ($3.tipo==real)) $$.valor.boolean = $1.valor.real == $3.valor.real;
		else if (($1.tipo==entero) && ($3.tipo==real)) $$.valor.boolean = $1.valor.entero == $3.valor.real;
		else if (($1.tipo==real) && ($3.tipo==entero)) $$.valor.boolean = $1.valor.real == $3.valor.entero;
		else yyerror("Solo se puede realizar operaciones booleanas sobre enteros y reales"); 
}|
		expresion_aritmetica NE expresion_aritmetica {		
		$$.tipo =boolean;		
		if (($1.tipo==entero) && ($3.tipo==entero)) $$.valor.boolean = $1.valor.entero != $3.valor.entero;
		else if (($1.tipo==real) && ($3.tipo==real)) $$.valor.boolean = $1.valor.real != $3.valor.real;
		else if (($1.tipo==entero) && ($3.tipo==real)) $$.valor.boolean = $1.valor.entero != $3.valor.real;
		else if (($1.tipo==real) && ($3.tipo==entero)) $$.valor.boolean = $1.valor.real != $3.valor.entero;
		else yyerror("Solo se puede realizar operaciones booleanas sobre enteros y reales"); 
};

%%

char* varToString(sym_value_type var){
   char *buffer = malloc(sizeof(char)*YYLMAX);
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

char* concatenarCadenas(sym_value_type s1, sym_value_type s2){
	char* buffer;
	int buffer_size;
	if ((s1.tipo==cadena) && (s2.tipo==cadena)){
		char *s1_mod = malloc(sizeof(char)*strlen(s1.valor.cadena));
		strncpy(s1_mod,s1.valor.cadena,strlen(s1.valor.cadena));
		s1_mod[strlen(s1_mod)-1]='\0'; /* Eliminar comilla del final */

		char *s2_mod = malloc(sizeof(char)*strlen(s2.valor.cadena));
		strncpy(s2_mod,s2.valor.cadena,strlen(s2.valor.cadena));
		s2_mod++; /* Eliminar primer elemento, la primera comilla en este caso*/

		/*fprintf(yyout,"....CONCATENANDO s1: %s y s2: %s\"\n",s1_mod, s2_mod);	*/

		buffer_size = snprintf(NULL,0, "%s%s", s1_mod, s2_mod);
		buffer = malloc(buffer_size+1);
		snprintf(buffer, buffer_size+1, "%s%s", s1_mod, s2_mod);
	}
	
	else if (s1.tipo==cadena){
		s1.valor.cadena[strlen(s1.valor.cadena)-1]='\0';
		if (s2.tipo==entero){	
			buffer_size = snprintf(NULL,0, "%s%d\"", s1.valor.cadena, s2.valor.entero);
buffer = malloc(buffer_size+1);

			snprintf(buffer, buffer_size+1, "%s%d\"", s1.valor.cadena, s2.valor.entero);
		}
		else if (s2.tipo==real){	
			buffer_size = snprintf(NULL, 0, "%s%.3f\"",s1.valor.cadena, s2.valor.real);		
buffer = malloc(buffer_size+1);
			snprintf(buffer, buffer_size+1, "%s%.3f\"",s1.valor.cadena, s2.valor.real);
		}
	}
	else if (s2.tipo==cadena){
		s2.valor.cadena++;
		if (s1.tipo==entero){
			buffer_size = snprintf(NULL, 0, "\"%d%s", s1.valor.entero, s2.valor.cadena);
buffer = malloc(buffer_size+1);
			snprintf(buffer, buffer_size+1, "\"%d%s", s1.valor.entero, s2.valor.cadena);
		}
		else if (s1.tipo==real){
			buffer_size = snprintf(NULL, 0, "\"%.3f%s", s1.valor.real,s2.valor.cadena);
buffer = malloc(buffer_size+1);
			snprintf(buffer, buffer_size, "\"%.3f%s", s1.valor.real,s2.valor.cadena);
		}
	}
	else yyerror("Algo ha fallado. No se ha podido concatenar.");

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
