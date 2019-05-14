#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "compiler.h"
#include "parser.tab.h"

#define reverse_list(type, list) \
  type* head = list; \
  type* next = head->next; \
  head->next = NULL; \
  while (next) { \
    type* tmp = next->next; \
    next->next = head; \
    head = next; \
    next = tmp; \
  } \

statement_t* reverse_statements(statement_t* statements) {
  if (!statements) return NULL;
  reverse_list(statement_t, statements);
  statement_t* statement = head;
  while (statement) {
    if (statement->type == IF) {
      statement->s.if_.statements = reverse_statements(statement->s.if_.statements);
      statement->s.if_.else_statements = reverse_statements(statement->s.if_.else_statements);
    } else if (statement->type == WHILE) {
      statement->s.while_.statements = reverse_statements(statement->s.while_.statements);
    }
    statement = statement->next;
  }
  return head;
}

routine_t* reverse(routine_t* routines) {
  reverse_list(routine_t, routines);
  routine_t* routine = head;
  while (routine) {
    routine->statements = reverse_statements(routine->statements);
    routine = routine->next;
  }
  return head;
}

void output_statements(statement_t* statements, routine_t* routines, int call_id) {
  statement_t* statement = statements;
  routine_t* routine = NULL;
  while (statement) {
    switch (statement->type) {
      case IF:
        if (statement->s.if_.raw) {
          printf("if (%s) {\n", statement->s.if_.condition);
        } else {
          printf("if (%s(data)) {\n", statement->s.if_.condition);
        }
        output_statements(statement->s.if_.statements, routines, call_id);
        printf("}\n");
        if (statement->s.if_.else_statements) {
          printf("else {\n");
          output_statements(statement->s.if_.else_statements, routines, call_id);
          printf("}\n");
        }
        break;
      case WHILE:
        if (statements->s.while_.raw) {
          printf("while (%s) {\n", statement->s.while_.condition);
        } else {
          printf("while (%s(data)) {\n", statement->s.while_.condition);
        }
        output_statements(statement->s.while_.statements, routines, call_id);
        printf("}\n");
        break;
      case EXEC:
        printf("%s(data);\n", statement->s.string);
        break;
      case AWAIT:
        printf("*state = %d%d;\n", call_id, statement->s.id);
        printf("return;\n");
        printf("case %d%d:\n", call_id, statement->s.id);
        break;
      case RAWC:
        printf("%s\n", statement->s.string);
        break;
      case CALL:
        routine = routines;
        while (routine) {
          if (strcmp(routine->name, statement->s.call_.sub) == 0) {
            output_statements(routine->statements, routines, statement->s.call_.id);
            break;
          }
          routine = routine->next;
        }
        break;
    }
    statement = statement->next;
  }
}

void compile(routine_t* routines) {
  routine_t* routine = reverse(routines);
  while (routine) {
    if (strcmp(routine->name, "__rawc") == 0) {
      printf("%s\n", routine->type);
    } else if (routine->is_main) {
      break;
    }
    routine = routine->next;
  }
  statement_t* statement = routine->statements;
  printf("void %s(int* state, %s) {\n", routine->name, routine->type);
  printf("switch (*state) {\n");
  printf("case 0:\n");
  output_statements(statement, routines, 1);
  printf("}\n");
  printf("}\n");
  while (routine) {
    if (strcmp(routine->name, "__rawc") == 0) {
      printf("%s\n", routine->type);
    }
    routine = routine->next;
  }
}

