%option noyywrap /*IMPORTANTE*/

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <calc.tab.h>

extern FILE *yyin;

%}

 /*DECLARATIONS*/


%%

 /*RULES*/

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


