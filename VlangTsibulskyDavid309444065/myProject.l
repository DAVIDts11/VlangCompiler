%{
#include "myProject.tab.h"
#include <string.h>
#include <stdio.h>

void yyerror (char *s);
int yylex();

%}

ALPHA [A-Za-z]
DIGIT [0-9]

%%
_vec_d                          {printf("_vec_d it is safe word - you not allow to use it .\n");yyterminate();}
_iterator_                      {printf("_iterator_ it is safe word - you not allow to use it .\n");yyterminate();}
scl                             return SCAL_TYPE;
vec                             return VECTOR_TYPE;
if                              return  IF ;
loop                            return  LOOP ;
print                           return  PRINT ;
[+-]                            {yylval.str = yytext[0] ;  return LOW_OPERATOR;}
[*/]                            {yylval.str = yytext[0] ;  return HIGH_OPERATOR;}
[,]                             {yylval.str = yytext[0] ;  return COMMA;}
[.]                             {yylval.str = yytext[0] ;  return DOT_OPERRATOR;}
[;]                             {yylval.str = yytext[0] ;  return SEMICOLON;}
[:]                             {yylval.str = yytext[0] ;  return INDEX;}
[=]                             {yylval.str = yytext[0] ;  return EQUAL;}
[\(]                            {yylval.str = yytext[0] ;  return OPEN_PARENTHESES;}
[\)]                            {yylval.str = yytext[0] ;  return CLOSE_PARENTHESES;}
[\{]                            {yylval.str = yytext[0] ;  return OPEN_BRACES;}
[\}]                            {yylval.str = yytext[0] ;  return CLOSE_BRACES;}
{ALPHA}({ALPHA}|{DIGIT})*       {strcpy(yylval.id,yytext);return ID;}
{DIGIT}+                        {strcpy(yylval.num,yytext); return NUM;}
[\[]{DIGIT}+([,]{DIGIT}+)*[\]]  {strcpy(yylval.vecDecl,yytext);return VEC_D;}
[ \t\n]                         ;
exit\n                          {yyterminate();}
.                               return yytext[0];
%%


int yywrap (void) {return 1;}


//
///   {ALPHA}({ALPHA}|{DIGIT})*    {strcpy(yylval.id,yytext);return ID;}
///   {DIGIT}+                     {yylval.num=atoi(yytext); return NUM;}
//   [\[]{DIGIT}([,]{DIGIT})*[\]] {return VEC_D;}
