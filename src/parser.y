%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "compiler.h"
#include "parser.tab.h"

#define YYDEBUG 1

int yylex();

int await_id = 0;

node_t* new_subroutine(char* name, statement_t* statements) {
  node_t* node = malloc(sizeof(node_t));
  node->val.subroutine.name = name;
  node->statements = statements;
  node->type = SUBROUTINE;
  node->next = NULL;
  return node;
}

int whitespace(char c) {
  return c == ' ' || c == '\n' || c == '\t' || c == '\r';
}

char* trim(char* string, int len) {
  int i = 0;
  while (string[i] && whitespace(string[i])) i++;
  int j = len - 1;
  while (j >= 0 && whitespace(string[j])) j--;
  string[j+1] = '\0';
  return &string[i];
}

node_t* new_coroutine(char* name, char* rettype, char* type, statement_t* statements) {
  node_t* node = malloc(sizeof(node_t));
  node->val.coroutine.name = name;
  node->statements = statements;
  type[strlen(type) - 1] = '\0';
  node->val.coroutine.type = type + 1;
  int retlen = strlen(rettype);
  rettype[retlen - 1] = '\0';
  node->val.coroutine.rettype = trim(rettype + 1, retlen - 2);
  node->type = ASYNC;
  node->next = NULL;
  return node;
}

node_t* add_node(node_t* nodes, node_t* node) {
  node->next = nodes;
  return node;
}

statement_t* add_stmt(statement_t* statements, statement_t* statement) {
  if (statements) {
    statement->next = statements;
  }
  return statement;
}

statement_t* new_exec(char* fn) {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->s.string = fn;
  statement->type = EXEC;
  statement->next = NULL;
  return statement;
}

statement_t* new_yield(char* val, int raw) {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->type = YIELD;
  statement->s.yield_.id = await_id++;
  statement->s.yield_.exp = val;
  statement->s.yield_.raw = raw;
  statement->next = NULL;
  return statement;
}

statement_t* new_call(char* sub_name, int id) {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->type = CALL;
  statement->s.call_.sub = sub_name;
  statement->s.call_.id = id;
  statement->next = NULL;
  return statement;
}

statement_t* new_if(char* condition, statement_t* statements, statement_t* else_statements, int raw) {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->type = IF;
  statement->s.if_.condition = condition;
  statement->s.if_.raw = raw;
  statement->s.if_.statements = statements;
  statement->s.if_.else_statements = else_statements;
  statement->next = NULL;
  return statement;
}

statement_t* new_while(char* condition, statement_t* statements, int raw) {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->type = WHILE;
  statement->s.while_.raw = raw;
  statement->s.while_.condition = condition;
  statement->s.while_.statements = statements;
  statement->next = NULL;
  return statement;
}

statement_t* new_rawc_stmt(char* rawc) {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->type = RAWC;
  statement->s.string = rawc;
  statement->next = NULL;
  return statement;
}

node_t* new_rawc(char* rawc) {
  node_t* node = malloc(sizeof(node_t));
  node->val.string = rawc;
  node->type = RAWC;
  node->statements = NULL;
  node->next = NULL;
  return node;
}

void yyerror (char const *s);
%}

%union {
  char* str;
  struct statement_s* statement;
  struct node_s* node;
  int num;
}

%token OPEN_BRACE CLOSE_BRACE SUBROUTINE ASYNC IF WHILE YIELD SEMICOLON ELSE EXEC
%token <num> CALL
%token <str> IDENT TYPE RAWC

%type <node> routine routines
%type <statement> stmt stmts block else if while yield

%%

program: routines { compile($1); }

routines: routines routine { $$ = add_node($1, $2); }
  | routine { $$ = $1; }
  ;

routine: ASYNC TYPE IDENT TYPE block { $$ = new_coroutine($3, $2, $4, $5); } 
  | SUBROUTINE IDENT block { $$ = new_subroutine($2, $3); }
  | RAWC { $$ = new_rawc($1); }
  ;

block: OPEN_BRACE stmts CLOSE_BRACE { $$ = $2; }

stmts:         { $$ = NULL; }
  | stmts stmt { $$ = add_stmt($1, $2); }
  ;

stmt: IDENT SEMICOLON    { $$ = new_exec($1); }
  | yield                { $$ = $1; }
  | if                   { $$ = $1; }
  | while                { $$ = $1; }
  | CALL IDENT SEMICOLON { $$ = new_call($2, $1); }
  | RAWC                 { $$ = new_rawc_stmt($1); }
  ;

if: IF IDENT block else { $$ = new_if($2, $3, $4, 0); }
  | IF RAWC block else  { $$ = new_if($2, $3, $4, 1); }
  ;

else:          { $$ = NULL; }
  | ELSE block { $$ = $2; }
  ;

while: WHILE IDENT block { $$ = new_while($2, $3, 0); }
  | WHILE RAWC block { $$ = new_while($2, $3, 1); }
  ;

yield: YIELD SEMICOLON    { $$ = new_yield(NULL, 0); }
  | YIELD IDENT SEMICOLON { $$ = new_yield($2, 0); }
  | YIELD RAWC SEMICOLON  { $$ = new_yield($2, 1); }
  ;

%%

void yyerror(char const *s) {
  printf("%s\n", s);
}

int main() {
  return yyparse();
}
