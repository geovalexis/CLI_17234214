%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <string.h>
#include <stdarg.h> 
#include "compiler.tab.h"
#define YYLMAX 100
#define SENTENCE_MAX_LENGTH 50

extern FILE *yyout;
extern int yylineno;
extern int yylex();
extern void yyerror(const char * s);
char *matriz_sentencias[YYLMAX];
void print_sentences();
int sq=1; /*siguiente squat (linea)*/
void emet(int args_count, ...);
int st=1; /*siguiente temporal*/
char* nou_temporal();
char *temp_sq;
void emet_calculation(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* oper);
void emet_salto_condicional(sym_value_type s1, const char* operel, sym_value_type s2, char* line2jump);
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
	char *cadena;
}

%token <variable> ID ID_ARITM ID_BOOL
%token <cadena> INTEGER REAL 
%token ASSIGN POTENCIA SUM REST MUL DIV MOD AND NEG OR FIN_SENTENCIA ABRIR_PAR CERRAR_PAR REPEAT DO DONE

%type <expr> expresion expresion_aritmetica  operacion_aritm_base operacion_aritm_prec1 operacion_aritm_prec2 M

%type <variable> id

%%

programa: lista_sentencias {print_sentences();};

lista_sentencias : lista_sentencias sentencia | sentencia;

sentencia: sentencia_simple | sentencias_iterativas;

sentencia_simple:  FIN_SENTENCIA| asignacion FIN_SENTENCIA | procedimientos FIN_SENTENCIA;

asignacion : id ASSIGN expresion { $1.value = $3;
				  sym_enter($1.nom, &$1.value);
				  emet(3, $1.nom, ":=", $3.lloc);}
;

id: ID | ID_ARITM;


expresion: expresion_aritmetica; /*Habrá que completarlo para la practica 3*/

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

sentencias_iterativas: sentencia_iterativa_incondicional; /*Habrá que añadir más en la P3*/

sentencia_iterativa_incondicional: REPEAT expresion_aritmetica M DO lista_sentencias DONE {
	if ($3.tipo==entero) emet(5, $3.lloc, ":=", $3.lloc, "ADDI", "1");
	else if ($3.tipo==real) emet(5, $3.lloc, ":=", $3.lloc, "ADDF", "1");
	else yyerror("Bad request");
	emet_salto_condicional($3, "LT", $2, temp_sq);
};


/* M contendrá la información del contador del bucle y guardará la línea donde empieza el bucle*/
M : {$$.lloc = malloc(sizeof(char)*5);
     $$.tipo = entero; /*Un contador siempre es un entero*/
     strcpy($$.lloc, nou_temporal());
     emet(3, $$.lloc, ":=", "0");
     temp_sq = malloc(sizeof(char)*5);
     sprintf(temp_sq, "%d", sq);     
};

procedimientos: put;

put: ID_ARITM {
	sym_lookup($1.nom, &$1.value);
	emet(2, "PARAM", $1.nom);
	char* oper = malloc(sizeof(char)*5);
	strcpy(oper, "PUT");
	if ($1.value.tipo==entero) strcat(oper, "I,");
	else if ($1.value.tipo==real) strcat(oper, "F,");
	emet(3, "CALL", oper, "1");
};

%%

void print_sentences(){
   int i;
   for (i=1; i < sq; i++)
	fprintf(yyout, "%d:  %s\n", i, matriz_sentencias[i]);
   fprintf(yyout, "%d:  HALT\n", sq);

}


void emet(int args_count, ...){

    va_list args; 
    va_start(args, args_count); 
    char *buffer = malloc(sizeof(char)*SENTENCE_MAX_LENGTH+1);
    int i;
    for (i=0; i < args_count; i++){  
         strcat(buffer,va_arg(args, char*)); 
         strcat(buffer," ");
    }
    matriz_sentencias[sq] = buffer;
    sq++;
    va_end(args); 

}

char* nou_temporal(){
  char* buffer = (char *) malloc(sizeof(char)*3+sizeof(int));
  sprintf(buffer, "$t0%d", st);
  st++;
  return buffer;
}

void emet_calculation(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* oper){
	char *oper_int = (char *)malloc(sizeof(char)*strlen(oper)+2); /*one xtra char for trailing zero */
	char *oper_float = (char *)malloc(sizeof(char)*strlen(oper)+2);
	strcpy(oper_int, oper);
	strcpy(oper_float, oper);
	strcat(oper_int, "I");
	strcat(oper_float, "F");

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

void emet_salto_condicional(sym_value_type s1, const char* operel, sym_value_type s2, char* line2jump){
	if (s1.tipo==s2.tipo) {
		char *op= (char *)malloc(sizeof(char)*strlen(operel)+2);
		strcpy(op, operel);
		if (s1.tipo==entero) strcat(op, "I");
	 	else strcat(op, "F");
		emet(6, "IF", s1.lloc, op, s2.lloc, "GOTO", line2jump);
		free(op);
	}
	else yyerror("Tienen que tener el mismo tipo!");

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
