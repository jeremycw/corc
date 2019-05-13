%{
#include "casync.tab.h"
%}

%%

"if"          { return IF; }
"else"        { return ELSE; }
"while"       { return WHILE; }
"await"       { return AWAIT; }
"call"        { return CALL; }
"async"       { return ASYNC; }
"sub"         { return SUBROUTINE; }
";"           { return SEMICOLON; }
"{"           { return OPEN_PAREN; }
"}"           { return CLOSE_PAREN; }
[a-zA-Z0-9_]+ { yylval.str = strdup(yytext); return IDENT; }
[ \t\n]       { }

%%
