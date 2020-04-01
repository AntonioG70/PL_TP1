%{
#include <string.h>
#include <stdlib.h>

const char* nome;
char *email;
char *author;

char* concat(const char *s1, const char *s2){
    char *result = malloc(strlen(s1) + strlen(s2) + 1);
    strcpy(result, s1);
    strcat(result, s2);
    return result;
}

void mv(const char* source, const char* dest){
  char com[100];
  sprintf(com, "mv %s %s", source, dest);
  system(com);

}

void mkdir(const char* d){
  char com[100];
  sprintf(com, "mkdir %s", d);
  system(com);
}

void touch(const char *d, ...){
  char com[100];
  sprintf(com, "touch %s", d);
  system(com);
}


%}
%option noyywrap

%x META TREE DIRECTORY

%%

<*>^\=\=\=                               {BEGIN INITIAL; }

\ meta                                   {BEGIN META; }

<META>^email:[ ].*                        {email = strdup(yytext + 7); }

<META>^author:[ ].*                       {author = strdup(yytext + 8); }

\ tree                                     {BEGIN TREE; }

<TREE>^\{%name%\}\/                        {mkdir(nome); }

<TREE>^-[^-]\{%name%\}\..*                 {char* r = concat(nome, yytext + 10); touch(r); mv(r, nome); }

<TREE>^-[^-][i?\w|\d]*\/                   {mkdir(yytext + 2); mv(yytext + 2, nome);}

<TREE>^-[^-]Makefile                       {touch(yytext + 2); mv(yytext + 2, nome);}

%%

int main(int argc, char const *argv[]){
  nome = argv[1];
  yylex();
  return(0);
}
