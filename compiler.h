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
  char* condition;
  struct statement_s* statements;
  int raw;
} while_t;

typedef struct statement_s {
  union {
    if_t if_;
    while_t while_;
    call_t call_;
    int id;
    char* string;
  } s;
  struct statement_s* next;
  int type;
} statement_t;

typedef struct routine_s {
  char* name;
  char* type;
  statement_t* statements;
  struct routine_s* next;
  int is_main;
} routine_t;

void compile(routine_t* routines);
