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
	}expr_bool; 
	sym_value_type expr_aritm;
	struct {
		int quad;
		ArrayList lls;
		char *lloc;
	}all_data;
	ArrayList sent;
	char *cadena;
	int entero;
}

%token <variable> ID ID_ARITM ID_BOOL
%token <cadena> INTEGER REAL 
%token <expr_bool> BOOLEAN_TRUE BOOLEAN_FALSE
%token <sent> FIN_SENTENCIA
%token ASSIGN POTENCIA SUM REST MUL DIV MOD AND NEG OR ABRIR_PAR CERRAR_PAR GT LT GE LE EQ NE BOOL_TRUE BOOL_FALSE REPEAT WHILE FOR IN TO DO UNTIL DONE IF THEN ELSE FI

%type <expr_aritm> expresion_aritmetica  operacion_aritm_base operacion_aritm_prec1 operacion_aritm_prec2 P R 
%type <expr_bool> expresion_bool operacion_boolean_prec1 operacion_boolean_prec2 operacion_boolean_base 

%type <sent> N lista_sentencias sentencia sentencia_simple sentencias_iterativas sentencias_condicionales sentencia_iterativa_incondicional sentencia_iterativa_condicional sentencia_iterativa_indexada asignacion

%type <cadena> operel
%type <entero> M
%type <variable> id
%type <all_data> Q
%%

programa: lista_sentencias {print_sentences();};

lista_sentencias : lista_sentencias M sentencia {
	   completa($1, $2);
	   $$ = $3;
}| sentencia;

sentencia: sentencia_simple | sentencias_iterativas | sentencias_condicionales;

sentencia_simple:  FIN_SENTENCIA| asignacion FIN_SENTENCIA {$$=$1;}| procedimientos FIN_SENTENCIA {$$=$2;};

asignacion : id ASSIGN expresion_aritmetica { 
				$1.value = $3;
				sym_enter($1.nom, &$1.value);
				emet(3, $1.nom, ":=", $3.lloc);
}|
			id ASSIGN expresion_bool {
				$1.value.tipo = boolean;
				if ($3.llf.size > 0) {
					$1.value.lloc = "0";
					completa($3.llf, sq);
					emet(3, $1.nom, ":=", "0");
					$$ = crea_lista(sq);
					emet(1, "GOTO");
				}

				if ($3.llc.size > 0) {
					$1.value.lloc = "1";
					completa($3.llc, sq);
					emet(3, $1.nom, ":=", "1");
					$$ = fusiona($$, crea_lista(sq)); /*fusiona() por si en el anterior if se ha añadido algo*/
					emet(1, "GOTO");
				}
				sym_enter($1.nom, &$1.value);
};

id: ID | ID_ARITM | ID_BOOL;


expresion_aritmetica: operacion_aritm_prec1 | 
		expresion_aritmetica SUM operacion_aritm_prec1 { emet_calculation(&($$), $1, $3, "ADD");}|
		expresion_aritmetica REST operacion_aritm_prec1 { emet_calculation(&($$), $1, $3, "SUB");}|
		SUM operacion_aritm_prec1 {$$=$2;}|			
		REST operacion_aritm_prec1 {
			$$.lloc = nou_temporal();
			$$.tipo = $2.tipo;
			if ($2.tipo==entero) emet(4, $$.lloc, ":=", "CHSI", $2.lloc);
			else emet(4, $$.lloc, ":=", "CHSF", $2.lloc);
}
;


operacion_aritm_prec1: 	operacion_aritm_prec2 | 
		operacion_aritm_prec1 MUL operacion_aritm_prec2 {emet_calculation(&($$), $1, $3, "MUL");}|
		operacion_aritm_prec1 DIV operacion_aritm_prec2 {
		if (($3.tipo==entero && atoi($3.lloc)==0) || ($3.tipo==real && atof($3.lloc)==0)){
			yyerror("No se puede dividir entre 0");
		}	
		else {	
			emet_calculation(&($$), $1, $3, "DIV");
		}
}|
		operacion_aritm_prec1 MOD operacion_aritm_prec2 {
		if ($1.tipo==entero && $3.tipo==entero){
			emet_calculation(&($$), $1, $3, "MOD");
		}
		else yyerror("Solo se puede obtener el modulo entre números ENTEROS");
}
;

operacion_aritm_prec2: operacion_aritm_base | operacion_aritm_prec2 POTENCIA operacion_aritm_base {
		if ($3.tipo==entero){
			int exponente = atoi($3.lloc);
			sym_value_type temp, result;
			temp.lloc = (char*)malloc(sizeof(char)*strlen($1.lloc)+2);
			strcpy(temp.lloc, $1.lloc);
			temp.tipo = $1.tipo;
			int i;
			for (i=0; i < exponente; i++){
				result.lloc=nou_temporal();
				emet_calculation(&result, $1, temp, "MUL");
				strcpy(temp.lloc, result.lloc);
			}	
			$$ = result;
		} else yyerror("OPERACION NO DISPONIBLE.");	
};


operacion_aritm_base: ABRIR_PAR expresion_aritmetica CERRAR_PAR { $$=$2;} |
	   INTEGER { $$.tipo=entero; $$.lloc=$1;}|
	   REAL { $$.tipo=real; $$.lloc=$1;} |
	   ID_ARITM {sym_lookup($1.nom, &$1.value); $$.tipo=$1.value.tipo; $$.lloc=$1.nom; }
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
	   emet_salto_condicional($1, $2, $3, "");
	   $$.llf = crea_lista(sq);
	   emet(1, "GOTO");
}|
	   BOOLEAN_TRUE { 
	   $$.llc = crea_lista(sq-1); /*emet(1, "GOTO");*/ /* -1 porque el emet se hará posteriorment*/
}|
	   BOOLEAN_FALSE {
	   $$.llf = crea_lista(sq-1); /*emet(1, "GOTO");*/
}|	
	   ID_BOOL {	
	sym_lookup($1.nom, &$1.value); 
	if (strcmp($1.value.lloc, "0")==0) $$.llf = crea_lista(sq-1);
	else if (strcmp($1.value.lloc, "1")==0) $$.llc = crea_lista(sq-1);
	else yyerror("Boolean not valid");
}
;

operel: GT {$$="GT";} | LT {$$="LT";} | GE {$$="GE";} | LE {$$="LE";} | EQ {$$="EQ";} | NE {$$="NE";};

sentencias_iterativas: sentencia_iterativa_incondicional | sentencia_iterativa_condicional | sentencia_iterativa_indexada;

sentencia_iterativa_incondicional: REPEAT expresion_aritmetica R M DO lista_sentencias DONE {
	if ($3.tipo==entero) emet(5, $3.lloc, ":=", $3.lloc, "ADDI", "1");
	else if ($3.tipo==real) emet(5, $3.lloc, ":=", $3.lloc, "ADDF", "1");
	else yyerror("Bad request");
	char *temp_sq = malloc(sizeof(char)*5);
    sprintf(temp_sq, "%d", $4);     
	emet_salto_condicional($3, "LT", $2, temp_sq);
};

sentencia_iterativa_condicional: WHILE M expresion_bool DO M lista_sentencias DONE {
	completa($3.llc, $5);
	completa($6, $2);
	$$= $3.llf;
	char *m_buffer = malloc(sizeof(char)*5);
    sprintf(m_buffer, "%d", $2); 
	emet(2, "GOTO", m_buffer);
}| DO M lista_sentencias UNTIL expresion_bool {
	completa($5.llc, $2);
	$$= $5.llf;			
};

sentencia_iterativa_indexada: Q DO lista_sentencias DONE {
	completa($3, sq);
	emet(5,$1.lloc, ":=", $1.lloc, "+", "1");
	char *quad_buffer = malloc(sizeof(char)*5);
    sprintf(quad_buffer, "%d", $1.quad); 
	emet(2, "GOTO", quad_buffer);
	$$ = $1.lls;
};

Q: P TO expresion_aritmetica {
	$$.quad = sq;
	char *quad_buffer = malloc(sizeof(char)*5);
    sprintf(quad_buffer, "%d", sq+2); 
	emet_salto_condicional($1, "LE", $3, quad_buffer);
	$$.lls = crea_lista(sq);
	emet(1, "GOTO");
	$$.lloc = $1.lloc;
};

P: FOR id IN expresion_aritmetica {
	emet(3,$2.nom, ":=", $4.lloc);
	$$.lloc = $2.nom;
	$$.tipo = $4.tipo; /* La variable será del tipo de la expresion_aritmetica asignada*/
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

/* Crea lista de siguientes */
N: {
   $$=crea_lista(sq);
   emet(1, "GOTO");
};

/* R contendrá la información del contador del bucle*/
R: {$$.lloc = malloc(sizeof(char)*5);
     $$.tipo = entero; /*Un contador siempre es un entero*/
     strcpy($$.lloc, nou_temporal());
     emet(3, $$.lloc, ":=", "0");
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
  for (j=0; j < l2.size; j++){
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
	char* op = (char *)malloc(sizeof(char)*strlen(oper)+2); /*one xtra char for trailing zero */
	strcpy(op, oper);

	if (s1.tipo==s2.tipo) {
		s0->lloc=nou_temporal();
		s0->tipo=s1.tipo;
		if (s1.tipo==entero){
			 strcat(op, "I");
		} else {
			 strcat(op, "F");
		}
		emet(5,s0->lloc, ":=", s1.lloc, op, s2.lloc);

	}
	else if (s1.tipo==real || s2.tipo==real){
		strcat(op, "F");
		s0->tipo=real;
		if (s1.tipo==real) {
			char *castedValue = nou_temporal();
			emet(4, castedValue, ":=", "I2F", s2.lloc);
			s0->lloc=nou_temporal();
			emet(5,s0->lloc, ":=", s1.lloc, op, castedValue);
		}
		else if (s2.tipo==real){
			char *castedValue = nou_temporal();
			emet(4, castedValue, ":=", "I2F", s1.lloc);
			s0->lloc=nou_temporal();
			emet(5,s0->lloc, ":=", castedValue, op, s2.lloc);
		}
		else yyerror("OPERACION NO PERMITIDA");
	}
	else yyerror("OPERACION NO PERMITIDA");
	free(op);
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
