%{
#include <string.h>
#include <stdlib.h>
#include <glib.h>


const char* nome;
char* name;
char *email;
char *author;
char currentDirectory[200] = "";
int currentTracos = -1;
GHashTable* files;
char* currentFile;

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

int contaTracos(char *t){
  int ti = 0;

  for(int i = 0; i < strlen(t); i++){
    if('-' == t[i]) ti++;
  }

  return ti;
}

void removeDirectory(char *t, int tracos){
  int pos = strlen(t) - 2;
  while(tracos > 0){
      if(t[pos] == '/') {tracos--;}
      else {t[pos] = '\0';}
      pos--;
  }
}

void updateDirectory(char *d){
  int tracos = contaTracos(d);
  if(tracos > currentTracos){
    strcat(currentDirectory, d + tracos + 1);
  }
  else{
    removeDirectory(currentDirectory, currentTracos - tracos + 1);
    strcat(currentDirectory, d + tracos + 1);
  }
  currentTracos = tracos;
}

void updateDirectoryCoragem(char *d, char* name){
  int tracos = contaTracos(d);
  if(tracos > currentTracos){
    strcat(currentDirectory, name);
  }
  else{
    removeDirectory(currentDirectory, currentTracos - tracos + 1);
    strcat(currentDirectory, name);
  }
  currentTracos = tracos;
}

void writeToFile(const char* f){
  FILE * file = fopen(currentFile, "a+");
  fputs(f, file);
  fclose(file);
}

gboolean hashCompare(gconstpointer s1, gconstpointer s2) {

  if(g_strcmp0(s1,s2) != 0){
    return TRUE;
  }

  return FALSE;

}

%}
%option noyywrap

%x META TREE DIRECTORY WRITE

%%

<*>^\=\=                                      {BEGIN INITIAL; }

\=[ ]meta                                     {BEGIN META; }

<META>^email:[ ].*                            {email = strdup(yytext + 7); }

<META>^author:[ ].*                           {author = strdup(yytext + 8); }

\=[ ]tree                                     {BEGIN TREE; }

<TREE>^\{%name%\}\/                           {strcat(currentDirectory, nome);
                                               strcat(currentDirectory,"/");
                                               mkdir(currentDirectory);
                                              }

<TREE>^[-]*[ ][A-Za-z0-9]*\/                  {updateDirectory(yytext);
                                               mkdir(currentDirectory);
                                              }

<TREE>^-[-]*[ ]\{%name%\}\..*                 {int trac = contaTracos(yytext);
                                               name = malloc(sizeof(char) * 30);
                                               strcpy(name, nome);
                                               char *extension = yytext + trac + 1 + 8;
                                               strcat(name, extension);
                                               updateDirectoryCoragem(yytext, name);
                                               touch(name);
                                               mv(name, currentDirectory);
                                               char* fileDirectory = strdup(currentDirectory);
                                               g_hash_table_insert(files, (gpointer) yytext + currentTracos + 1, (gpointer) fileDirectory);
                                              }

<TREE>^-[-]*[ ][A-Za-z0-9\.]*$                {updateDirectory(yytext);
                                                touch(yytext + currentTracos + 1);
                                                mv(yytext + currentTracos + 1, currentDirectory);
                                                char* fileDirectory = strdup(currentDirectory);;
                                                g_hash_table_insert(files, (gpointer) yytext + currentTracos + 1, (gpointer) fileDirectory);
                                              }

\=[ ].*                                       {BEGIN WRITE;
                                               char* fileName = strdup(yytext + 2);
                                               currentFile = g_hash_table_lookup(files, fileName);
                                              }

<WRITE>.|\n                                   {writeToFile(yytext);}

<WRITE>\{%name%\}                             {writeToFile(nome);}

<WRITE>\{%author%\}                           {writeToFile(author);}

<WRITE>\{%email%\}                            {writeToFile(email);}



%%

int main(int argc, char const *argv[]){
  nome = argv[1];
  files = g_hash_table_new(g_str_hash , hashCompare);
  yylex();
  return(0);
}
