%{
#include "parser.tab.h"

int call_id = 2;
%}

%%

"if"          { return IF; }
"else"        { return ELSE; }
"while"       { return WHILE; }
"await"       { return AWAIT; }
"call"        { yylval.num = call_id++; return CALL; }
"async"       { return ASYNC; }
"sub"         { return SUBROUTINE; }
\(.*\)        { yylval.str = strdup(yytext); return TYPE; }
";"           { return SEMICOLON; }
"{"           { return OPEN_BRACE; }
"}"           { return CLOSE_BRACE; }
[a-zA-Z0-9_]+ { yylval.str = strdup(yytext); return IDENT; }
[ \t\n]       { }

%%
