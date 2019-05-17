echo-server: echo.c
	clang echo.c -l ev -o echo-server

echo.c: echo.co ../src/cocc
	../src/cocc < echo.co > echo.c

../src/cocc:
	cd ../src
	make

