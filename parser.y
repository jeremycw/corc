%{

#include <stdio.h>
#include <stdlib.h>

#define YYDEBUG 1

int yylex();

typedef struct {
  char* condition;
  struct statement_s* statements;
  struct statement_s* else_statements;
} if_t;

typedef struct {
  char* condition;
  struct statement_s* statements;
} while_t;

typedef struct statement_s {
  union {
    if_t if_;
    while_t while_;
    int id;
    char* string;
  } s;
  struct statement_s* next;
  int type;
} statement_t;

typedef struct routine_s {
  char* name;
  statement_t* statements;
  struct routine_s* next;
  int is_main;
} routine_t;

int await_id = 0;

routine_t* new_routine(char* name, statement_t* statements, int is_main) {
  routine_t* routine = malloc(sizeof(routine_t));
  routine->name = name;
  routine->statements = statements;
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

statement_t* new_call(char* sub_name) {
  statement_t* statement = malloc(sizeof(statement_t));
  statement->type = CALL;
  statement->s.string = sub_name;
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

void compile(routine_t* routines) {
  routine_t* routine = routines;
  while (routine) {
    printf("%s\n", routine->name);
    routine = routine->next;
  }
}

void yyerror (char const *s);
%}

%union {
  char* str;
  struct statement_s* statement;
  struct routine_s* routine;
}

%token OPEN_PAREN CLOSE_PAREN SUBROUTINE ASYNC IF WHILE AWAIT SEMICOLON CALL ELSE EXEC
%token <str> IDENT

%type <routine> routine routines
%type <statement> stmt stmts block else

%%

program: routines { compile($1); }

routines: routines routine { $$ = add_routine($1, $2); }
  | routine { $$ = $1; }
  ;

routine: ASYNC IDENT block { $$ = new_routine($2, $3, 1); } 
  | SUBROUTINE IDENT block { $$ = new_routine($2, $3, 0); }
  ;

block: OPEN_PAREN stmts CLOSE_PAREN { $$ = $2 } ;

stmts:         { $$ = NULL; }
  | stmts stmt { $$ = add_stmt($1, $2); }
  ;

stmt: IDENT SEMICOLON    { $$ = new_exec($1); }
  | AWAIT SEMICOLON      { $$ = new_await(); }
  | IF IDENT block else  { $$ = new_if($2, $3, $4); }
  | WHILE IDENT block    { $$ = new_while($2, $3); }
  | CALL IDENT SEMICOLON { $$ = new_call($2); }
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
