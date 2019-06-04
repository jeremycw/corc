echo-server: echo.c fiber.h
	$(CC) echo.c -l ev -o echo-server

echo.c: echo.co ../src/corc
	../src/corc < echo.co > echo.c

../src/corc:
	cd ../src; make

