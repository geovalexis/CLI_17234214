%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <string.h>
#include "calc.tab.h"
#define YYLMAX 100

extern FILE *yyin;
char *string_buffer;

%}

%option yylineno
%x comment
%x cadena

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

"-"?{digit}({digit})* 	{yylval.entero = atoi(yytext);
			return INTEGER;}

"-"?{digit}+"."{digit}+((?i:e)"-"?{digit}*)? 	{yylval.real = atof(yytext);
						return REAL;}
			
{suma} {return SUM;}

{resta} {return REST;}

{mult}[^/{mult}] {return MUL;}

{pot}/{digit} {return POTENCIA;}

{div}[^/*] {return DIV;}

{mod} {return MOD;}

{abrir_par} {return ABRIR_PAR;}

{cerrar_par} {return CERRAR_PAR;}

 /* comparadores booleanos */
">"  {return GT;}
">=" {return GE;}
"<" {return LT;} 
"<=" {return LE;}
"=" {return EQ;}
"<>" {return NE;}

 /* operadores booleanos */
"not" {return NEG;}
"and" {return AND;}
"or"  {return OR;}

 /* booleanos */
"true" 	{yylval.boolean = true;
	return BOOLEAN;}
"false" {yylval.boolean = false;
	return BOOLEAN;}	

 /* COMENTARIOS */
{comentario_linea}(.)*{linebreak}  {}
{comentario_bloque_abrir} {BEGIN(comment);} 	/* activar condición */
<comment>[^*]*  {}	/* eat anything that's not a '*'  */
<comment>"*"+[^*/]* {}	/* eat up '*' not followed by '/'s  */ 
<comment>{comentario_bloque_cerrar}{linebreak}? {BEGIN(INITIAL);} 	/* restaurar estado del sistema */

 /* CADENAS DE TEXTO */

\"[^\n\"]+\"		{yylval.str = (char *)malloc(sizeof(char)*yyleng);
					 strncpy(yylval.str,yytext,yyleng);
					 return CADENA;}

 /* IDENTIFICADORES. Importante que esta ultima definicion esté a lo último por si hay alguna coincidencia con palabras reservadas */
{letra}({letra}|{digit})*    {  sym_value_type value;
				yylval.variable.nom = (char *)malloc(sizeof(char)*yyleng);
				strncpy(yylval.variable.nom,yytext,yyleng);
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

if(yyin == NULL){
	error = EXIT_FAILURE;
}else{
	error = EXIT_SUCCESS;
}

return error;

}

int end_analisi_lexic(){

int error;

error = fclose(yyin);

if (error == 0){

error = EXIT_SUCCESS;
}else{
error = EXIT_FAILURE;
}
return error;

}


