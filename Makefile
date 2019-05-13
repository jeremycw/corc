casync: casync.tab.o lex.yy.o
	clang casync.tab.o lex.yy.o -o $@

casync.tab.c: casync.y
	bison -d $<

lex.yy.c: casync.l
	flex $<

clean:
	@rm *.o lex.yy.c casync.tab.*
