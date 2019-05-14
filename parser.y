%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "compiler.h"

#define YYDEBUG 1

int yylex();

int await_id = 0;

routine_t* new_routine(char* name, statement_t* statements, char* type, int is_main) {
  routine_t* routine = malloc(sizeof(routine_t));
  routine->name = name;
  routine->statements = statements;
  if (type) {
    type[strlen(type) - 1] = '\0';
    routine->type = type + 1;
  } else {
    routine->type = NULL;
  }
  routine->is_main = is_main;
  routine->next = NULL;
  return routine;
}

routine_t* add_routine(routine_t* routines, routine_t* routine) {
  routine->next = routines;
  return routine;
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

statement_t* new_await() {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->type = AWAIT;
  statement->s.id = await_id++;
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

statement_t* new_if(char* condition, statement_t* statements, statement_t* else_statements) {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->type = IF;
  statement->s.if_.condition = condition;
  statement->s.if_.statements = statements;
  statement->s.if_.else_statements = else_statements;
  statement->next = NULL;
  return statement;
}

statement_t* new_while(char* condition, statement_t* statements) {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->type = WHILE;
  statement->s.while_.condition = condition;
  statement->s.while_.statements = statements;
  statement->next = NULL;
  return statement;
}

routine_t* new_rawc(char* rawc) {
  routine_t* routine = malloc(sizeof(routine_t));
  routine->name = "__rawc";
  routine->statements = NULL;
  routine->type = rawc;
  routine->is_main = 0;
  routine->next = NULL;
  return routine;
}

void yyerror (char const *s);
%}

%union {
  char* str;
  struct statement_s* statement;
  struct routine_s* routine;
  int num;
}

%token OPEN_BRACE CLOSE_BRACE SUBROUTINE ASYNC IF WHILE AWAIT SEMICOLON ELSE EXEC
%token <num> CALL
%token <str> IDENT TYPE RAWC

%type <routine> routine routines
%type <statement> stmt stmts block else

%%

program: routines { compile($1); }

routines: routines routine { $$ = add_routine($1, $2); }
  | routine { $$ = $1; }
  ;

routine: ASYNC IDENT TYPE block { $$ = new_routine($2, $4, $3, 1); } 
  | SUBROUTINE IDENT block { $$ = new_routine($2, $3, NULL, 0); }
  | RAWC { $$ = new_rawc($1); }
  ;

block: OPEN_BRACE stmts CLOSE_BRACE { $$ = $2 } ;

stmts:         { $$ = NULL; }
  | stmts stmt { $$ = add_stmt($1, $2); }
  ;

stmt: IDENT SEMICOLON    { $$ = new_exec($1); }
  | AWAIT SEMICOLON      { $$ = new_await(); }
  | IF IDENT block else  { $$ = new_if($2, $3, $4); }
  | WHILE IDENT block    { $$ = new_while($2, $3); }
  | CALL IDENT SEMICOLON { $$ = new_call($2, $1); }
  ;

else:          { $$ = NULL; }
  | ELSE block { $$ = $2; }
  ;

%%

void yyerror(char const *s) {
  printf("%s\n", s);
}

int main() {
  yydebug = 1;
  if (yyparse()) {
    printf("Failure!\n");
  } else {
    printf("Success!\n");
  }
  return 0;
}
