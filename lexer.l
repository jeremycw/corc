%{
#include "parser.tab.h"

int call_id = 2;
char* raw_buf = NULL;
int raw_count = 0;
int raw_capacity = 128;

%}

%x raw

%%

"if"          { return IF; }
"else"        { return ELSE; }
"while"       { return WHILE; }
"await"       { return AWAIT; }
"call"        { yylval.num = call_id++; return CALL; }
"async"       { return ASYNC; }
"sub"         { return SUBROUTINE; }
\([^\)]*\)    { yylval.str = strdup(yytext); return TYPE; }
"{%"          { BEGIN(raw); }
<raw>"%}"     {
  BEGIN(INITIAL);
  raw_buf[raw_count] = '\0';
  yylval.str = raw_buf;
  raw_buf = NULL;
  raw_count = 0;
  raw_capacity = 128;
  return RAWC;
}
<raw>(.|\n)   {
  if (!raw_buf || raw_count == raw_capacity) {
    raw_capacity *= 2;
    raw_buf = realloc(raw_buf, raw_capacity);
  }
  char c = yytext[0];
  raw_buf[raw_count] = c;
  raw_count++;
}
";"           { return SEMICOLON; }
"{"           { return OPEN_BRACE; }
"}"           { return CLOSE_BRACE; }
[a-zA-Z0-9_]+ { yylval.str = strdup(yytext); return IDENT; }
[ \t\n]       { }

%%
