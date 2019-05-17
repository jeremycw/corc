# cocc

Stackless coroutine compiler for C

## Purpose

Unstructured state machines are not a good solution for asynchronous logic. They
have all the same problems as `goto` making the logic of your program very difficult
to follow. This compiler allows you to add stackless coroutines to your C program.
These coroutines enable you to structure your asynchronous logic in a more readable
and maintainable way.

## Usage

### Build the compiler

`cd src; make`

### Example Program

```c
{%

struct example_s {
  int i;
  int count_twice;
};

void increment(struct example_s* ctx) {
  ctx->i++;
}

int twice(struct example_s* ctx) {
  return ctx->count_twice;
}

%} //inject raw c into your program

//define the return type, name and argument type of the coroutine
coroutine (int) count_to_five(struct example_s*) {
  if twice { //conditions can be calls to procedures like this or raw c
    //use {% and %} to drop down to C when convenient the argument can be accessed via arg
    {% arg->i = 0; %}
    call count; //call subroutines with the call keyword
    {% arg->i = 0; %}
    call count;
  } else {
    {% arg->i = 0; %}
    call count;
  }
}

sub count { //define a subroutine
  while {% arg->i <= 5 %} {
    increment; //call procedures that operate on the argument
    yield {% arg->i; %}; //yield a return value
  }
}

{%

int main() {
  int state = 0; //stores the state of the coroutine
  struct example_s ctx = { .i = 0, .count_twice = 1 };

  //cocc generates a procedure that takes an int pointer and the argument type
  call_count_to_five(&state, &ctx); //returns 1
  call_count_to_five(&state, &ctx); //returns 2
  call_count_to_five(&state, &ctx); //returns 3
  call_count_to_five(&state, &ctx); //returns 4
  call_count_to_five(&state, &ctx); //returns 5

  call_count_to_five(&state, &ctx); //returns 1
  call_count_to_five(&state, &ctx); //returns 2
  call_count_to_five(&state, &ctx); //returns 3
  call_count_to_five(&state, &ctx); //returns 4
  call_count_to_five(&state, &ctx); //returns 5
}

%}
```

The compiler operates on standard input and output. To compile this program:
`cocc < example.co > example.c`

Take a look at `examples/echo.co` for a more real world example that implements
fibers and an echo server on top of libev.

