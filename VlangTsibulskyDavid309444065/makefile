myProject.exe: lex.yy.c myProject.tab.c
	gcc -Wimplicit-function-declaration myProject.tab.c -o myProject.exe

lex.yy.c: myProject.tab.c myProject.l
	flex myProject.l

myProject.tab.c: myProject.y
	bison -d myProject.y

clean: 
	del lex.yy.c myProject.tab.c myProject.tab.h myProject.exe