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

node_t* reverse(node_t* nodes) {
  reverse_list(node_t, nodes);
  node_t* node = head;
  while (node) {
    node->statements = reverse_statements(node->statements);
    node = node->next;
  }
  return head;
}

void output_statements(statement_t* statements, node_t* root, int call_id) {
  statement_t* statement = statements;
  node_t* node = NULL;
  while (statement) {
    switch (statement->type) {
      case IF:
        if (statement->s.if_.raw) {
          printf("if (%s) {\n", statement->s.if_.condition);
        } else {
          printf("if (%s(arg)) {\n", statement->s.if_.condition);
        }
        output_statements(statement->s.if_.statements, root, call_id);
        printf("}\n");
        if (statement->s.if_.else_statements) {
          printf("else {\n");
          output_statements(statement->s.if_.else_statements, root, call_id);
          printf("}\n");
        }
        break;
      case WHILE:
        if (statement->s.while_.raw) {
          printf("while (%s) {\n", statement->s.while_.condition);
        } else {
          printf("while (%s(arg)) {\n", statement->s.while_.condition);
        }
        output_statements(statement->s.while_.statements, root, call_id);
        printf("}\n");
        break;
      case EXEC:
        printf("%s(arg);\n", statement->s.string);
        break;
      case YIELD:
        printf("*state = %d%d;\n", call_id, statement->s.yield_.id);
        if (!statement->s.yield_.exp) {
          printf("return;\n");
        } else if (statement->s.yield_.raw) {
          printf("return %s\n", statement->s.yield_.exp);
        } else {
          printf("return %s(arg);\n", statement->s.yield_.exp);
        }
        printf("case %d%d:\n", call_id, statement->s.yield_.id);
        break;
      case RAWC:
        printf("%s\n", statement->s.string);
        break;
      case CALL:
        node = root;
        while (node) {
          if (
            node->type == SUBROUTINE &&
            strcmp(node->val.subroutine.name, statement->s.call_.sub) == 0
          ) {
            output_statements(node->statements, root, statement->s.call_.id);
            break;
          }
          node = node->next;
        }
        break;
    }
    statement = statement->next;
  }
}

void compile(node_t* root) {
  root = reverse(root);
  node_t* node = root;
  while (node) {
    if (node->type == RAWC) {
      printf("%s\n", node->val.string);
    } else if (node->type == ASYNC) {
      statement_t* statement = node->statements;
      coroutine_t coro = node->val.coroutine;
      printf("%s call_%s(int* state, %s arg) {\n", coro.rettype, coro.name, coro.type);
      printf("switch (*state) {\n");
      printf("case 0:\n");
      output_statements(statement, root, 1);
      printf("}\n");
      printf("}\n");
    }
    node = node->next;
  }
}

