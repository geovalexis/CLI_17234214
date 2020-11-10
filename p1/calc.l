%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "calc.tab.h"

extern FILE *yyin;

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
ini_fin_cadena \"

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

{ini_fin_cadena}.*{ini_fin_cadena} 	{yylval.str = (char *)malloc(sizeof(char)*yyleng);
					 strncpy(yylval.str,yytext,yyleng);
					 return CADENA;}			
{suma} {return SUM;}

{resta}[^/{digit}] {return REST;}

{mult}[^/{mult}] {return MUL;}

{pot} {return POTENCIA;}

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

 /* importante que esta ultima definicion esté a lo último por si hay alguna coincidencia con palabras reservadas */
{letra}({letra}|{digit})*    {yylval.variable.nom = (char *)malloc(sizeof(char)*yyleng);
				strncpy(yylval.variable.nom,yytext,yyleng);
				return ID;}	


{comentario_linea}+(.)*  {return FIN_SENTENCIA;}

{comentario_bloque_abrir} {BEGIN(comment); return FIN_SENTENCIA;} 	/* activar condición */
<comment>[^*{linebreak}]*  {}	/* eat anything that's not a '*'  */
<comment>"*"+[^*/{linebreak}]* {}	/* eat up '*' not followed by '/'s  */ 
<comment>{linebreak}  {}
<comment>{comentario_bloque_cerrar} {BEGIN(INITIAL);} 	/* restaurar estado del sistema */

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

