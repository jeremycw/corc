corc: parser.tab.o lex.yy.o compiler.o
	$(CC) -W -Wall $^ -ll -o $@

parser.tab.c: parser.y
	bison -d $<

lex.yy.c: lexer.l
	flex $<

.PHONY: clean

clean:
	@rm *.o
	@rm lex.yy.c parser.tab.* corc
