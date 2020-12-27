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
void emet_calculation(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* oper);
void emet_salto_condicional(sym_value_type s1, const char* operel, sym_value_type s2, char* line2jump);
ArrayList crea_lista(int num);
ArrayList fusiona(ArrayList l1, ArrayList l2);
void completa(ArrayList lista, int num);
%}

%code requires {
	#include "symtab.h"
	typedef struct {
		int *lista;
		int size;
	}ArrayList;
}


%union{
	struct{
		char *nom;	
		sym_value_type value;
	}variable;
	struct {
		ArrayList llf;
		ArrayList llc;
		sym_value_type value;
	}expr;
	ArrayList sent;
	char *cadena;
	int entero;
}

%token <variable> ID ID_ARITM ID_BOOL
%token <cadena> INTEGER REAL 
%token <expr> BOOLEAN_TRUE BOOLEAN_FALSE
%token <sent> FIN_SENTENCIA
%token ASSIGN POTENCIA SUM REST MUL DIV MOD AND NEG OR ABRIR_PAR CERRAR_PAR GT LT GE LE EQ NE BOOL_TRUE BOOL_FALSE REPEAT WHILE FOR IN DO UNTIL DONE IF THEN ELSE FI

%type <expr> expresion expresion_aritmetica  operacion_aritm_base operacion_aritm_prec1 operacion_aritm_prec2 P expresion_bool operacion_boolean_prec1 operacion_boolean_prec2 operacion_boolean_base

%type <sent> N lista_sentencias sentencia sentencia_simple sentencias_iterativas sentencias_condicionales sentencia_iterativa_incondicional

%type <cadena> operel
%type <entero> M
%type <variable> id

%%

programa: lista_sentencias {print_sentences();};

lista_sentencias : lista_sentencias M sentencia {
	   completa($1, $2);
	   $$ = $3;
}| sentencia;

sentencia: sentencia_simple | sentencias_iterativas | sentencias_condicionales;

sentencia_simple:  FIN_SENTENCIA| asignacion FIN_SENTENCIA {$$=$2;}| procedimientos FIN_SENTENCIA {$$=$2;};

asignacion : id ASSIGN expresion { $1.value = $3.value;
				  sym_enter($1.nom, &$1.value);
				  emet(3, $1.nom, ":=", $3.value.lloc);}
;

id: ID | ID_ARITM | ID_BOOL;


expresion: expresion_aritmetica | expresion_bool;

expresion_aritmetica: operacion_aritm_prec1 | 
		expresion_aritmetica SUM operacion_aritm_prec1 { emet_calculation(&($$.value), $1.value, $3.value, "ADD");}|
		expresion_aritmetica REST operacion_aritm_prec1 { emet_calculation(&($$.value), $1.value, $3.value, "SUB");}|
		SUM operacion_aritm_prec1 {$$=$2;}|			
		REST operacion_aritm_prec1 {
			$$.value.lloc = nou_temporal();
			$$.value.tipo = $2.value.tipo;
			if ($2.value.tipo==entero) emet(4, $$.value.lloc, ":=", "CHSI", $2.value.lloc);
			else emet(4, $$.value.lloc, ":=", "CHSF", $2.value.lloc);
}
;


operacion_aritm_prec1: 	operacion_aritm_prec2 | 
		operacion_aritm_prec1 MUL operacion_aritm_prec2 {emet_calculation(&($$.value), $1.value, $3.value, "MUL");}|
		operacion_aritm_prec1 DIV operacion_aritm_prec2 {
		if (($3.value.tipo==entero && atoi($3.value.lloc)==0) || ($3.value.tipo==real && atof($3.value.lloc)==0)){
			yyerror("No se puede dividir entre 0");
		}	
		else {	
			emet_calculation(&($$.value), $1.value, $3.value, "DIV");
		}
}|
		operacion_aritm_prec1 MOD operacion_aritm_prec2 {
		if ($1.value.tipo==entero && $3.value.tipo==entero){
			emet_calculation(&($$.value), $1.value, $3.value, "MOD");
		}
		else yyerror("Solo se puede obtener el modulo entre números ENTEROS");
}
;

operacion_aritm_prec2: operacion_aritm_base | operacion_aritm_prec2 POTENCIA operacion_aritm_base {
		if ($3.value.tipo==entero){
			int exponente = atoi($3.value.lloc);
			sym_value_type temp, result;
			temp.lloc = (char*)malloc(sizeof(char)*strlen($1.value.lloc)+2);
			strcpy(temp.lloc, $1.value.lloc);
			temp.tipo = $1.value.tipo;
			int i;
			for (i=0; i < exponente; i++){
				result.lloc=nou_temporal();
				emet_calculation(&result, $1.value, temp, "MUL");
				strcpy(temp.lloc, result.lloc);
			}	
			$$.value = result;
		} else yyerror("OPERACION NO DISPONIBLE.");	
};


operacion_aritm_base: ABRIR_PAR expresion_aritmetica CERRAR_PAR { $$=$2;} |
	   INTEGER { $$.value.tipo=entero; $$.value.lloc=$1;}|
	   REAL { $$.value.tipo=real; $$.value.lloc=$1;} |
	   ID_ARITM {sym_lookup($1.nom, &$1.value); $$.value.tipo=$1.value.tipo; $$.value.lloc=$1.nom; }
;

expresion_bool: operacion_boolean_prec1 | 
		expresion_bool OR M operacion_boolean_prec1 {
		completa($1.llf, $3);
		$$.llc = fusiona($1.llc, $4.llc);
		$$.llf = $4.llf;
}; 

operacion_boolean_prec1: operacion_boolean_prec2 |
		operacion_boolean_prec1 AND M operacion_boolean_prec2 {
		completa($1.llc, $3);
		$$.llc = $4.llc;
		$$.llf = fusiona($1.llf, $4.llf);
}; 

operacion_boolean_prec2: operacion_boolean_base | 
		NEG operacion_boolean_prec2 {
		$$.llc=$2.llf;
		$$.llf=$2.llc;
}; 

operacion_boolean_base: ABRIR_PAR expresion_bool CERRAR_PAR { $$=$2;} | 
	   expresion_aritmetica operel expresion_aritmetica {
	   $$.llc = crea_lista(sq);
	   emet_salto_condicional($1.value, $2, $3.value, "");
	   $$.llf = crea_lista(sq);
	   emet(1, "GOTO");
}|
	   BOOLEAN_TRUE { 
	   $$.llc = crea_lista(sq); emet(1, "GOTO");
}|
	   BOOLEAN_FALSE {
	   $$.llf = crea_lista(sq); emet(1, "GOTO");
}|	
	   ID_BOOL { sym_lookup($1.nom, &$1.value); $$.value.tipo=$1.value.tipo; $$.value.lloc=$1.nom;}
;

operel: GT {$$="GT";} | LT {$$="LT";} | GE {$$="GE";} | LE {$$="LE";} | EQ {$$="EQ";} | NE {$$="NE";};

sentencias_iterativas: sentencia_iterativa_incondicional; /*Habrá que añadir más en la P3*/

sentencia_iterativa_incondicional: REPEAT expresion_aritmetica P M DO lista_sentencias DONE {
	if ($3.value.tipo==entero) emet(5, $3.value.lloc, ":=", $3.value.lloc, "ADDI", "1");
	else if ($3.value.tipo==real) emet(5, $3.value.lloc, ":=", $3.value.lloc, "ADDF", "1");
	else yyerror("Bad request");
	char *temp_sq = malloc(sizeof(char)*5);
        sprintf(temp_sq, "%d", $4);     
	emet_salto_condicional($3.value, "LT", $2.value, temp_sq);
};


sentencias_condicionales: IF expresion_bool THEN M lista_sentencias FI {
	completa($2.llc, $4);
	$$=fusiona($2.llf, $5);
}| 
	IF expresion_bool THEN M lista_sentencias ELSE N M lista_sentencias FI{
	completa($2.llc, $4);
	completa($2.llf, $8);
	$$=fusiona($5, fusiona($7, $9));
};

/* Guarda el quat actual */
M: {
   $$=sq;
};

N: {
   $$=crea_lista(sq);
   emet(1, "GOTO");
}

/* P contendrá la información del contador del bucle*/
P : {$$.value.lloc = malloc(sizeof(char)*5);
     $$.value.tipo = entero; /*Un contador siempre es un entero*/
     strcpy($$.value.lloc, nou_temporal());
     emet(3, $$.value.lloc, ":=", "0");
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

ArrayList crea_lista(int num){
   ArrayList temp;
   temp.lista = malloc(YYLMAX*sizeof(int));
   temp.lista[0]=num;
   temp.size = 1;
   return temp;
}

ArrayList fusiona(ArrayList l1, ArrayList l2){
  ArrayList temp;
  temp.lista = malloc(YYLMAX*sizeof(int));
  int i;
  for (i=0; i < l1.size; i++){
	temp.lista[i]=l1.lista[i];
  }
  int j;
  for (j=0; i < l2.size; j++){
	temp.lista[i]=l2.lista[j];
        i++;
  }

  temp.size = l1.size + l2.size;
  return temp;
}

void completa(ArrayList lista, int num){
  int i;
  char* num_buffer = malloc(sizeof(char)*5);
  sprintf(num_buffer, "%d", num);
  for (i=0; i < lista.size; i++){
	strcat(matriz_sentencias[lista.lista[i]],num_buffer);
  }
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
		else yyerror("OPERACION NO PERMITIDA");
	}
	else yyerror("OPERACION NO PERMITIDA");
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
