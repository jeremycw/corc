all: echo-server http-server

http-server: http_server.c fiber.h http_parser.c http_parser.h varray.h
	$(CC) -O3 http_server.c http_parser.c -l ev -o http-server

http_server.c: http_server.co ../src/corc
	../src/corc < http_server.co > http_server.c

echo-server: echo.c fiber.h
	$(CC) echo.c -l ev -o echo-server

echo.c: echo.co ../src/corc
	../src/corc < echo.co > echo.c

../src/corc:
	cd ../src; make

