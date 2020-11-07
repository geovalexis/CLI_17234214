/***************** ESPECIFICACIO LEX ***************/

/*

Exemple 7: ID := DIGIT 

*/

/***************************************************/
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "exemple7y.h"

extern FILE *yyin;

%}

%option yylineno

lletra	[a-zA-Z]
digit	[0-9]

%%


{lletra}({lletra}|{digit})*	{
				
				yylval.ident.lexema = (char *)malloc(sizeof(char)*yyleng);
				strncpy(yylval.ident.lexema,yytext,yyleng);
				yylval.ident.lenght = yyleng;
				yylval.ident.line = yylineno;
				return ID;
				}	


":="	{
	return ASSIGN;
	}	

{digit}({digit})* 	{
			yylval.enter=atoi(yytext);
			return INTEGER;
			}	
.	{}

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
