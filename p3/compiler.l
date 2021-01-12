%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <string.h>
#include "compiler.tab.h"
#define YYLMAX 100

extern FILE *yyin;
char *string_buffer;

%}

%option yylineno
%x comment

digit [0-9]
letra [a-zA-Z]
linebreak "\n"
espacio [ \t\r]
comentario_linea "//"
comentario_bloque_abrir "/*"
comentario_bloque_cerrar "*/"

suma "+"
resta "-"
mult "*"
div "/"
mod "mod"
pot "**"
asignacion ":="
abrir_par "("
cerrar_par ")"

%%


{asignacion}	{return ASSIGN;}

"-"?{digit}({digit})* 	{yylval.cadena = (char *)malloc(sizeof(char)*yyleng+1);
			strncpy(yylval.cadena,yytext,yyleng+1); 
			return INTEGER;}

"-"?{digit}+"."{digit}+((?i:e)"-"?{digit}*)? 	{yylval.cadena = (char *)malloc(sizeof(char)*yyleng+1);
						strncpy(yylval.cadena,yytext,yyleng+1); 
						return REAL;}


 /* EXPRESIONES ARITMETICAS */ 			
{suma} {return SUM;}

{resta} {return REST;}

{mult} {return MUL;}

{pot} {return POTENCIA;}

{div}[^/*] {return DIV;}

{mod} {return MOD;}

{abrir_par} {return ABRIR_PAR;}

{cerrar_par} {return CERRAR_PAR;}

 /* OPERADORES RELACIONALES */
">"  {return GT;}
">=" {return GE;}
"<" {return LT;} 
"<=" {return LE;}
"=" {return EQ;}
"<>" {return NE;}

 /* OPERADORES BOOLEANOS */
"not" {return NOT;}
"and" {return AND;}
"or"  {return OR;}

 /* LITERALES BOOLEANOS */
"true" 	{return BOOLEAN_TRUE;}

"false" {return BOOLEAN_FALSE;}

 /*SENTENCIAS ITERATIVAS */
"repeat" {return REPEAT;};
"while" {return WHILE;};
"for" {return FOR;};
"in" {return IN;};
".." {return TO;};
"do" {return DO;};
"until" {return UNTIL;};
"done" {return DONE;};

 /* SENTENCIAS CONDICIONALES */
"if" {return IF;};
"then" {return THEN;};
"else" {return ELSE;};
"fi" {return FI;};

 /* COMENTARIOS */
{comentario_linea}(.)*{linebreak}  {}
{comentario_bloque_abrir} {BEGIN(comment);} 	/* activar condición */
<comment>[^*]*  {}	/* eat anything that's not a '*'  */
<comment>"*"+[^*/]* {}	/* eat up '*' not followed by '/'s  */ 
<comment>{comentario_bloque_cerrar}{linebreak}? {BEGIN(INITIAL);} 	/* restaurar estado del sistema */


 /* IDENTIFICADORES. Importante que esta ultima definicion esté a lo último por si hay alguna coincidencia con palabras reservadas */
{letra}({letra}|{digit})*    {  sym_value_type value;
				yylval.variable.nom = (char *)malloc(sizeof(char)*yyleng+1); 
				strncpy(yylval.variable.nom,yytext,yyleng+1);
				if (sym_lookup(yytext, &value) == SYMTAB_OK) {
					if (value.tipo==boolean) return ID_BOOL;
					else return ID_ARITM;
				} else return ID;}


{linebreak} {} {return FIN_SENTENCIA;}/* eat up linebreaks */

{espacio}+  {} /* eat up whitespaces */

. {printf( "Unrecognized character: %s\n", yytext );}


%%

int init_analisi_lexic(char *file_name)
{
	int error;
	yyin=fopen(file_name,"r");
	if(yyin == NULL) error = EXIT_FAILURE;
	else error = EXIT_SUCCESS;
	return error;
}

int end_analisi_lexic()
{
	int error;
	error = fclose(yyin);
	if (error == 0) error = EXIT_SUCCESS;
	else error = EXIT_FAILURE;
	return error;
}


