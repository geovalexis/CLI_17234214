%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <string.h>
#include <stdarg.h> 
#include "calc.tab.h"
#define YYLMAX 100

extern FILE *yyout;
extern int yylineno;
extern int yylex();
extern void yyerror(const char * s);
int sq=1; /*siguiente squat (linea)*/
void emet(int args_count, ...);
int st=1; /*siguiente temporal*/
char* nou_temporal();
void emet_calculation(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* oper);

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
	char *entero, *real;
}

%token <variable> ID ID_ARITM ID_BOOL
%token <entero> INTEGER 
%token <real> REAL 
%token ASSIGN POTENCIA SUM REST MUL DIV MOD AND NEG OR FIN_SENTENCIA ABRIR_PAR CERRAR_PAR

%type <expr> expresion expresion_aritmetica  operacion_aritm_base operacion_aritm_prec1 operacion_aritm_prec2


%%

programa: lista_declaraciones | lista_sentencias;

lista_declaraciones: 

lista_sentencias : lista_sentencias sentencia | sentencia;

sentencia:  FIN_SENTENCIA | expresion FIN_SENTENCIA {emet(1, $1);} | asignacion FIN_SENTENCIA;

asignacion : ID ASSIGN expresion { $1.value = $3;
				  sym_enter($1.nom, &$1.value);
				  emet(3, $1.nom, ":=", $3.lloc);}
;


expresion: expresion_aritmetica;

expresion_aritmetica: operacion_aritm_prec1 | 
		expresion_aritmetica SUM operacion_aritm_prec1 { emet_calculation(&$$, $1, $3, "ADD");}|
		expresion_aritmetica REST operacion_aritm_prec1 { emet_calculation(&$$, $1, $3, "SUB");}|
		SUM operacion_aritm_prec1 {$$=$2;}|			
		REST operacion_aritm_prec1 {
			$$.lloc = nou_temporal();
			$$.tipo = $2.tipo;
			if ($2.tipo==entero) emet(4, $$.lloc, ":=", "CHSI", $2.lloc);
			else emet(4, $$.lloc, ":=", "CHSF", $2.lloc);
}
;


operacion_aritm_prec1: 	operacion_aritm_prec2 | 
		operacion_aritm_prec1 MUL operacion_aritm_prec2 {emet_calculation(&$$, $1, $3, "MUL");}|
		operacion_aritm_prec1 DIV operacion_aritm_prec2 {
		if (($3.tipo==entero && atoi($3.lloc)==0) || ($3.tipo==real && atof($3.lloc)==0)){
			yyerror("No se puede dividir entre 0");
		}	
		else {	
			emet_calculation(&$$, $1, $3, "DIV");
		}
}|
		operacion_aritm_prec1 MOD operacion_aritm_prec2 {
		if ($1.tipo==entero && $3.tipo==entero){
			emet_calculation(&$$, $1, $3, "MOD");
		}
		else yyerror("Solo se puede obtener el modulo entre números ENTEROS");
}
;

operacion_aritm_prec2: operacion_aritm_base | operacion_aritm_prec2 POTENCIA operacion_aritm_base {
		/*TODO: comprobar TIPO*/
		int exponente = atoi($3.lloc);
		sym_value_type temp;
		int i;
		for (i=0; i < exponente; i++){
			temp.lloc=nou_temporal();
			emet_calculation(&temp, $1, $1, "MUL");
		}	
		$$ = temp;	
};


operacion_aritm_base: ABRIR_PAR expresion_aritmetica CERRAR_PAR { $$=$2;} |
	   INTEGER { $$.tipo=entero; $$.lloc=$1;}|
	   REAL { $$.tipo=real; $$.lloc=$1;} |
	   ID_ARITM {sym_lookup($1.nom, &$1.value); $$.tipo=$1.value.tipo; $$.lloc=$1.nom; }
;



%%


void emet(int args_count, ...){

    fprintf(yyout,"%d:  ", sq);
    sq++;

    va_list args; 
    va_start(args, args_count); 
    int i; 
    for (i = 0; i < args_count; i++)  
         fprintf(yyout,"%s ", va_arg(args, char*)); 
    fprintf(yyout, "\n");
    va_end(args); 

}

char* nou_temporal(){
  char* buffer = (char *) malloc(sizeof(char)*3+sizeof(int));
  sprintf(buffer, "$t%d", st);
  st++;
  return buffer;
}

void emet_calculation(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* oper){
	char *oper_int = (char *)malloc(sizeof(char)*strlen(oper)+2); /*one xtra char for trailing zero */
	char *oper_float = (char *)malloc(sizeof(char)*strlen(oper)+2);
	strcpy(oper_int, oper);
	strcpy(oper_float, oper);
	strncat(oper_int, "I", 1);
	strncat(oper_float, "F", 1);

	if (s1.tipo==s2.tipo) {
		s0->lloc=nou_temporal();
		s0->tipo=s1.tipo;
		char* op = s1.tipo==entero ? oper_int : oper_float;
		emet(5,s0->lloc, ":=", s1.lloc, op, s2.lloc);
	}
	else if (s1.tipo==real || s2.tipo==real){
		s0->tipo=real;
		if (s1.tipo==real) {
			char *castedValue = nou_temporal();
			emet(4, castedValue, ":=", "I2F", s2.lloc);
			s0->lloc=nou_temporal();
			emet(5,s0->lloc, ":=", s1.lloc, oper_float, castedValue);
		}
		else if (s2.tipo==real){
			char *castedValue = nou_temporal();
			emet(4, castedValue, ":=", "I2F", s1.lloc);
			s0->lloc=nou_temporal();
			emet(5,s0->lloc, ":=", castedValue, oper_float, s2.lloc);
		}
		else s0->tipo=-1;
	}
	else s0->tipo=-1;
	free(oper_int);
	free(oper_float);
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
