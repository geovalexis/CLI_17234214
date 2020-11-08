%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

%%


{asignacion}	{return ASSIGN;}

"-"?{digit}({digit})* 	{yylval.enter=atoi(yytext);return INTEGER;}

"-"?{digit}+"."{digit}+((?i:e)"-"?{digit}*)? 	{yylval.real=atof(yytext);return REAL;}

{ini_fin_cadena}.*{ini_fin_cadena} 	{yylval.string = (char *)malloc(sizeof(char)*yyleng);
					 strncpy(yylval.ident.lexema,yytext,yyleng);
					 return CADENA;}			
{suma} {return SUMA;}

{resta}[^/{digit}] {return RESTA;}

{mult}[^/{mult}] {return MULTIPLICACION;}

{pot} {return POTENCIA;}

{div}[^/*] {return DIVISION;}

{mod} {return MODULO;}


 /* comparadores booleanos */
">"  {return MAYOR_QUE;}
">=" {return MAYOR_IGUAL_QUE;}
"<" {return MENOR_QUE;} 
"<=" {return MENOR_IGUAL_QUE;}
"=" {return IGUAL_QUE;}
"<>" {return DIFF_DE;}

 /* operadores booleanos */
"not" {return NEG;}
"and" {return AND;}
"or"  {return OR;}

 /* booleanos */
"true" 	{return BOOL_TRUE;}
"false" {return BOOL_FALSE;}

 /* importante que esta ultima definicion esté a lo último por si hay alguna coincidencia con palabras reservadas */
{letra}({letra}|{digit})*    {yylval.ident.lexema = (char *)malloc(sizeof(char)*yyleng);
				strncpy(yylval.ident.lexema,yytext,yyleng);
				yylval.ident.lenght = yyleng;
				yylval.ident.line = yylineno;
				return ID;}	


{comentario_linea}+(.)*  {}

{comentario_bloque_abrir} {BEGIN(comment);} 	/* activar condición */
<comment>[^*{linebreak}]*  {}	/* eat anything that's not a '*'  */
<comment>"*"+[^*/{linebreak}]* {}	/* eat up '*' not followed by '/'s  */ 
<comment>{linebreak}  {}
<comment>{comentario_bloque_cerrar} {BEGIN(INITIAL);} 	/* restaurar estado del sistema */

{linebreak} {} /* eat up linebreaks */

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


