#ifndef COMPILER_H
#define COMPILER_H

typedef struct {
  char* condition;
  struct statement_s* statements;
  struct statement_s* else_statements;
  int raw;
} if_t;

typedef struct {
  char* sub;
  int id;
} call_t;

typedef struct {
  char* exp;
  int raw;
  int id;
} yield_t;

typedef struct {
  char* condition;
  struct statement_s* statements;
  int raw;
} while_t;

typedef struct statement_s {
  union {
    if_t if_;
    while_t while_;
    call_t call_;
    yield_t yield_;
    int id;
    char* string;
  } s;
  struct statement_s* next;
  int type;
} statement_t;

typedef struct {
  char* name;
} subroutine_t;

typedef struct {
  char* name;
  char* type;
  char* rettype;
} coroutine_t;

typedef struct node_s {
  union {
    coroutine_t coroutine;
    subroutine_t subroutine;
    char* string;
  } val;
  struct node_s* next;
  statement_t* statements;
  int type;
} node_t;

void compile(node_t* root);

#endif
