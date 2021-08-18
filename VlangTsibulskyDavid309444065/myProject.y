%{
    int yylex();
  
    void yyerror (char *s);
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdbool.h>
    #include "lex.yy.c"
    #include<ctype.h>
 
   

  // globle variables:
    extern  FILE * yyout ;
    extern FILE* yyin;
    bool  firstTimInFunc ;
    int  _i_=0;
    char _temp_[7]="_vec_d";
    int _vecSize_ = 0;
    enum Type{scl, vec};
    enum lineType{assigment_type,statement_type,printStatem_type};

    //print to file c functions :
    void printFileHead();
    void printIncluds();
    void printFunctions();
    void startMain();

    //functions to parse:
    void getID(char* _res,char* _id);
    void getVec_d(char* _res,char* _vec_d);
    void assignExp(char* _res,char* _id,char* _exp);
    void operatorAction(char* _res,char* _exp_l,char* _exp_r ,char _Op);
    void printToStFile(char* statement,enum lineType _type);
    void assignEnd(char* statement,char* assignment) ;
    void assignIndexxExp(char* _dest,char* _vec_id, char* _index,char* _righEq);
    void loopStatement(char* statement_dest,char* exp,char* inner_statement);
    void ifStatement(char* statement_dest,char* exp,char* inner_statement);
    void printStAction(char * printSt,char * _printable);
    void parentessisExp(char *_dest,char _lp,char* _exp,char rp);

    //struct node for linked list of variables :
    typedef struct Variable {
        char id[10];
        enum Type type ;
        int size ;  
        struct Variable * next ;   
    } variable;
    variable * Head ;

    //functions for variable  linked list : 
    void addToList(char _id[],enum Type _type,char _chSize[]);
    variable * getNodeById(char _id[]);

%}



%start line
%union {
    char num[10]; 
    char vecDecl[10];
    char str; 
    char id[10]; 
    char exp[3000];
    char term[50];
    }       

%token <id> ID
%token <num> NUM 
%token <vecDecl> VEC_D
%token SCAL_TYPE VECTOR_TYPE LOOP IF PRINT
%token <str> SEMICOLON COMMA 
%token <str>   OPEN_PARENTHESES CLOSE_PARENTHESES 
%token <str>   OPEN_BRACES  CLOSE_BRACES
%type  <id> define_scl 
%type  <id> define_vector 
%type  <exp> statement 

%type  <exp> EXP  assignment  printStatement 
%type  <term> TERM  PRINTABLE 

%right <str> EQUAL
%left  <str> LOW_OPERATOR 
%left  <str> HIGH_OPERATOR
%left  <str> DOT_OPERRATOR INDEX

%%

line              : define_scl SEMICOLON 
                  | define_vector SEMICOLON
                  | assignment SEMICOLON                               {printToStFile($1,assigment_type);}
                  | printStatement SEMICOLON                           {printToStFile($1,printStatem_type);}
                  | statement                                          {printToStFile($1,statement_type);} 
                  | line  define_scl SEMICOLON 
                  | line  define_vector SEMICOLON
                  | line  assignment SEMICOLON                          {printToStFile($2,assigment_type);}
                  | line printStatement SEMICOLON                       {printToStFile($2,printStatem_type);}
                  | line  statement                                     {printToStFile($2,statement_type);}
                  ;


define_scl        : SCAL_TYPE ID                                        {addToList($2,scl,"0"); fprintf(yyout,"\tint %s ; \n",$2);}
                  ;

define_vector     : VECTOR_TYPE ID OPEN_BRACES NUM CLOSE_BRACES         {addToList($2,vec,$4); fprintf(yyout,"\tint %s[%s] ; \n",$2,$4);}  
                  ;   

statement         : assignment SEMICOLON                                {assignEnd($$,$1);} 
                  | LOOP EXP OPEN_BRACES statement CLOSE_BRACES         {loopStatement($$,$2,$4);}    
                  | IF EXP OPEN_BRACES statement CLOSE_BRACES           {ifStatement($$,$2,$4);}
                  | statement statement                                 {snprintf($$,500,"%s\n%s\n",$1,$2);}
                  | printStatement SEMICOLON                            {snprintf($$,400,"%s\n",$1);}
                  | ID INDEX EXP EQUAL EXP SEMICOLON                    {assignIndexxExp($$,$1,$3,$5);}
                  ; 
    
assignment        :  ID EQUAL EXP                                       {assignExp($$,$1,$3);}     
                  |  ID EQUAL assignment                                {assignExp($$,$1,$3);}
                  ; 

printStatement    : PRINT PRINTABLE                                     {printStAction($$,$2);}
                  ;   

PRINTABLE         : EXP                                                 {snprintf($$,150,"%s",$1);}
                  | PRINTABLE COMMA EXP                                 {snprintf($$,150,"%s!%s",$1,$3);}      
                  ;  

EXP               : EXP  LOW_OPERATOR EXP                               {operatorAction($$,$1,$3,$2);}
                  | EXP  HIGH_OPERATOR EXP                              {operatorAction($$,$1,$3,$2);}
                  | EXP  DOT_OPERRATOR EXP                              {operatorAction($$,$1,$3,$2);}
                  | EXP  INDEX EXP                                      {operatorAction($$,$1,$3,$2);}
                  | TERM                                                {;}
                  | OPEN_PARENTHESES EXP CLOSE_PARENTHESES              {parentessisExp($$,$1,$2,$3);}
                  ; 


TERM              : ID                                                  {getID($$,$1);}
                  | NUM                                                 {snprintf($$,1000,"*%s",$1);}
                  | VEC_D                                               {getVec_d($$,$1);}
                  ;  








%%


void printStAction(char * printSt,char * _printable)
{
   char * token = strtok(_printable, "!");
   snprintf(printSt,10,"");
   char tmp[400];

   while( token != NULL ) {
      if (token[0]=='*')
      {
         token++;
         snprintf(tmp,400,"printf(\"%%d\",%s);\n",token);
         strcat(printSt, tmp);
      } 
      else if (token[0]=='#')
      {
          token++;
          snprintf(tmp,400,"printVector(%s,%d);\n",token,_vecSize_);
          strcat(printSt, tmp);
      }
      else
      {
         printf("Unknown type to print .\n");
         exit(EXIT_FAILURE);
      }
      token = strtok(NULL, "!");
   }
    snprintf(tmp,400,"\tprintf(\"\\n\");\n");
    strcat(printSt, tmp);
   _vecSize_= 0 ;
}

void loopStatement(char* statement_dest,char* exp,char* inner_statement)
{
   if(exp[0]=='#')
   {
       printf("In LOOP statement must be scl type to defing number of iterations\n");
       exit(EXIT_FAILURE);
   }
    else if (exp[0]=='*')
    {
        exp++;
        snprintf(statement_dest,500,"\tfor(int _iterator_ =0;_iterator_<%s;_iterator_++)\n\t{\n%s\n\t}\n",exp,inner_statement) ;
    }
    else 
    {
       printf("Unknown variable in LOOP statement \n");
       exit(EXIT_FAILURE);
    }
}

void ifStatement(char* statement_dest,char* exp,char* inner_statement)
{
   if(exp[0]=='#')
   {
       printf("In IF statement must be scl for condition\n");
       exit(EXIT_FAILURE);
   }
    else if (exp[0]=='*')
    {
        exp++;
        snprintf(statement_dest,500,"\tif(%s)\n\t{\n%s\n\t}\n",exp,inner_statement) ;
    }
    else 
    {
       printf("Unknown variable in IF statement \n");
       exit(EXIT_FAILURE);
    }
}

void assignEnd(char* statement,char* assignment)
{
    assignment++;
    snprintf(statement,150,"\t%s;\n",assignment) ;
    _vecSize_= 0 ;
}

void printToStFile(char* statement,enum lineType _type)
{
  
    if (_type==assigment_type  )
    {
          statement++;
          fprintf(yyout,"\t%s;\n",statement) ;
    }
    else if (_type == printStatem_type)           
    {
        fprintf(yyout,"\t%s\n",statement) ;
    }
    else
    {
          fprintf(yyout,"%s\n",statement) ;
    }
}


void operatorAction(char* _res,char* _exp_l,char* _exp_r ,char _Op)
{
    if(_exp_l[0] == '*' && _exp_r[0]=='*')  // scl opp scl
    {
        _exp_l++;
        _exp_r++;
        if(_Op=='+' || _Op=='-'||_Op=='*' ||_Op=='/' )
        {
           snprintf(_res,100,"*(%s %c %s)",_exp_l ,_Op,_exp_r) ;
        }
        else
        {
              printf("Incorrect operation - you can't use %c with scl and scl",_Op);
              exit(EXIT_FAILURE);
        }

    }else if(_exp_l[0] == '#' && _exp_r[0]=='*')  // vec opp scl
    {
        _exp_l++;
        _exp_r++;
        if(_Op=='+' || _Op=='-'||_Op=='*' ||_Op=='/' )
        {
           snprintf(_res,100,"#vecSclOp(%s,\'%c\',%s,%d)",_exp_l ,_Op,_exp_r,_vecSize_) ;
        }else  if(_Op==':')
        {
           snprintf(_res,100,"*getByIndex(%s,%s)",_exp_l ,_exp_r) ;
        }
        else
        {
              exit(EXIT_FAILURE);
        }    

    }else if(_exp_l[0] == '#' && _exp_r[0]=='#')  // vec opp vec
    {
        _exp_l++;
        _exp_r++;
         if(_Op=='+' || _Op=='-'||_Op=='*' ||_Op=='/' )
        {
           snprintf(_res,100,"#vecVecOp(%s,\'%c\',%s,%d)",_exp_l ,_Op,_exp_r,_vecSize_) ;
        }else  if(_Op==':')
        {
           snprintf(_res,100,"#vecColonOp(%s,%s,%d)",_exp_l ,_exp_r,_vecSize_) ;
        }else  if(_Op=='.')
        {
           snprintf(_res,100,"*vecDotOp(%s,%s,%d)",_exp_l,_exp_r,_vecSize_) ;
        }
        else 
        {
              printf("Incorrect operation - you can't use %c with vec and vec",_Op);
              exit(EXIT_FAILURE);
        }   

    }else if(_exp_l[0] == '*' && _exp_r[0]=='*') // csl opp vec
    {
        printf("Incorrect  operation .");
        exit(EXIT_FAILURE);
    }else                                        
    {
          printf("Unkown types to operate .");
          exit(EXIT_FAILURE);
    }
}

void parentessisExp(char *_dest,char _lp,char* _exp,char _rp)
{
    char sign = _exp[0];
    snprintf(_dest,1000,"%c%c %s %c",sign,_lp,++_exp,_rp);
}

 void assignExp(char* _res,char* _id,char* _exp)
 {
    variable * tempNode = getNodeById(_id);
     if(tempNode->type==scl)
     {
       if(_exp[0]=='#')
        {
          printf("Can't assign vec to scl");
          exit(EXIT_FAILURE);
        } else
        if(_exp[0]=='*')
        {
            _exp++;
            snprintf(_res,100,"*%s = %s",_id ,_exp) ;
        }
        else
        {
          printf("Unkown type to assign");
          exit(EXIT_FAILURE);
        }

     }
     else if(tempNode->type == vec)
     {
       int _size = tempNode->size ;
       if(_exp[0]=='#')
        {
             _exp++;
           snprintf(_res,100,"#assingVecToVec(%s,%s,%d)",_id ,_exp,_size) ;
        }
        else if(_exp[0]=='*')
        {
             _exp++;
           snprintf(_res,100,"#assignSclToVec(%s,%s,%d)",_id ,_exp,_size) ;
        }
        else
        {
          printf("Unkown type to assign");
          exit(EXIT_FAILURE);
        }
     }
     else
     {
          printf("Can't match type to  variable %s ",_id);
          exit(EXIT_FAILURE);
     }
 }

void assignIndexxExp(char* _dest,char* _vec_id, char* _index,char* _righEq)
{

    variable * tempNode = getNodeById(_vec_id);
    if(tempNode->type==vec && _index[0] =='*' && _righEq[0])
    {
        _index++;
        _righEq++;
        snprintf(_dest,100,"%s[%s] = %s;\n",_vec_id,_index,_righEq) ;
        _vecSize_ = 0;    
    }
    else
    {
         printf("Can't asign  \":\" operation .");
         exit(EXIT_FAILURE);
    }
}

 void getVec_d(char* _res,char* _vec_d)
 {

     char tempVar[10];
     snprintf(tempVar,10,"%s%d",_temp_,_i_) ;
     _i_++;
     _vec_d++;                        //remove 1 char
     _vec_d[strlen(_vec_d)-1] = '\0';    //remove last char
     printf("_vec_d = %s\n" ,_vec_d);
    
    char * token = strtok(_vec_d, ",");

    fprintf(yyout,"\tint %s[] = {",tempVar) ;
    int size = 0;
    while( token != NULL )
    {
        fprintf(yyout,"%s",token) ;
        size++;
        token = strtok(NULL, ",");
        if( token != NULL )
            fprintf(yyout,",") ;
     }
        fprintf(yyout,"};\n") ;
    if(_vecSize_)
       if(_vecSize_!=size)
       {
          printf("Sizes of vectors doesn't match .");
          exit(EXIT_FAILURE);
       }
    _vecSize_ = size ;
    char buffer[10];
    addToList(tempVar,vec,itoa(size,buffer,10));
    snprintf(_res,1000,"#%s",tempVar) ;
 }


void getID(char* _res,char* _id)
{
     variable * tempNode = getNodeById(_id);

     if(tempNode->type==scl)
     {
         snprintf(_res,1000,"*%s",_id) ;
     }
     else if(tempNode->type == vec)
     {
      if(_vecSize_)
      {
       if(_vecSize_!=tempNode->size)
       {
          printf("Sizes of vectors doesn't match .");
          exit(EXIT_FAILURE);
       }
      }
        _vecSize_ = tempNode->size ;
        snprintf(_res,1000,"#%s",_id) ;
     }
     else
     {
          printf("Can't match type to  variable %s ",_id);
          exit(EXIT_FAILURE);
     }
}

void printFileHead()
{
  printIncluds();
  printFunctions();
  startMain();
}

void printIncluds()
{
   fprintf(yyout,"#include <stdio.h>\n#include <stdlib.h>\n\n\n") ;  
}

void printFunctions()
{
    
    fprintf(yyout,"int* assignSclToVec(int _vec[],int _scl,int _size)\n{\n"
                  "\tfor(int i=0;i<_size;i++)\n\t\t{\n\t\t\t_vec[i] =_scl;\n\t\t}\n\treturn _vec;\n}\n");
    
    fprintf(yyout,"int* assingVecToVec(int _dest[], int _sours[],int _size_d)\n{\n"
                  "\tfor(int i=0;i<_size_d;i++)\n\t\t{\n\t\t\t_dest[i] =_sours[i];\n\t\t}\n\treturn _dest;\n}\n");

    fprintf(yyout,"int vecDotOp(int _left[], int _right[] , int _size) \n{"
	             "\n\tint sum =0;\n\tfor (int i = 0; i < _size; i++)\n\t{\n\t\tsum+=_left[i] * _right[i];\n\t}\n\treturn sum;\n}\n");

    fprintf(yyout,"int *vecColonOp(int _left[], int _right[], int _size)\n{\n\tint *temp_vec = (int *)malloc(sizeof(int) * _size);"
	                 "\n\tfor (int i = 0; i < _size; i++)\n\t{\n\t\ttemp_vec[i] = _left[_right[i]];\n\t}\n\treturn temp_vec ;\n}\n");

    fprintf(yyout,"int getByIndex(int _vec[], int _index)\n{\n\treturn _vec[_index];\n}\n");

    fprintf(yyout,"int *vecSclOp(int *_left, char _op, int _right, int _size)\n{\n\tfor (int i = 0; i < _size; i++)"
            "\n\t{\n\t\tswitch (_op)\n\t\t{\n\t\tcase '+':\n\t\t\t_left[i] += _right;\n\t\t\tbreak;"
            " \n\t\tcase '-':\n\t\t\t_left[i] -= _right;\n\t\t\tbreak;\n\t\tcase '*':\n\t\t\t_left[i] *= _right;"
            "\n\t\t\tbreak;\n\t\tcase '/':\n\t\t\tif (!_right)\n\t\t\t{\n\t\t\t\tprintf(\"You can't devide by zerro .\");"
            " \n\t\t\t\texit(EXIT_FAILURE);\n\t\t\t}\n\t\t\t_left[i] /= _right;\n\t\t\tbreak;\n\t\tdefault:"
            "\n\t\t\tprintf(\"Unknown operator .\");\n\t\t}\n\t}\n\treturn _left;\n}\n");

    fprintf(yyout,"int *vecVecOp(int _left[], char _op, int _right[], int _size)\n{\n\tfor (int i = 0; i < _size; i++)"
	        "\n\t{\n\t\tswitch (_op)\n\t\t{\n\t\tcase '+':\n\t\t\t_left[i] += _right[i];\n\t\t\tbreak;\n\t\tcase '-':"
	        "\n\t\t\t_left[i] -= _right[i];\n\t\t\tbreak;\n\t\tcase '*':\n\t\t\t_left[i] *= _right[i];\n\t\t\tbreak;"
	        "\n\t\tcase '/':\n\t\t\tif (!_right)\n\t\t\t{\n\t\t\t\tprintf(\"You can't devide by zerro .\");"
	        "\n\t\t\t\texit(EXIT_FAILURE);\n\t\t\t}\n\t\t\t_left[i] /= _right[i];\n\t\t\tbreak;\n\t\tdefault:"
	        "\n\t\t\tprintf(\"Unknown operator .\");\n\t\t}\n\t}\n\treturn _left;\n}\n");

    fprintf(yyout,"void printVector(int * _vec, int size)\n{\n\tprintf(\"[\");\n\tfor (int i = 0; i < size-1; i++)"
            "\n\t{\n\t\tprintf(\"%%d,\",_vec[i]);\n\t}\n\tprintf(\"%%d\",_vec[size-1]);\n\tprintf(\"] \");\n}\n");

}

void startMain()
{
   fprintf(yyout,"\n\nint main()\n{\n") ;  
}



int main(int argc, char *argv[])
 {


   if (argc == 1)
   {
        yyout = fopen("parsed.c", "w");
         	if(!yyout)
         	{
         	    fprintf(stderr, "Can't open file parsed.c towrite in.\n");
         	    return 1;
         	}
   }
   else if (argc == 3)
   {
          yyin = fopen(argv[1], "r");
          if(!yyin)
              {
         	      fprintf(stderr, "Can't open file  : %s \n",argv[2]);
         	      return 1;
              }

          yyout = fopen(argv[2], "w");
          if(!yyout)
              {
         	      fprintf(stderr, "Can't open file : %s  \n" , argv[3]);
         	      return 1;
              }
   }
   else 
   {
          printf("Incorect input - you should use 2 argument : "
                "input file ,outputfile.  Or no arguments at all .");
          return 1;
   }
 
  Head = (variable*)malloc(sizeof(variable));
   if(Head==NULL)
    {
        printf("couldn't allocate new node");
        exit(EXIT_FAILURE);
    }
  Head->next = NULL ;
 firstTimInFunc = true ;

  printFileHead();
  yyparse();
  fprintf(yyout,"\treturn 0 ; \n}") ;  
  if(yyin)
    fclose(yyin);
  fclose(yyout);
  return  0 ; 
 }

void addToList(char _id[],enum Type _type, char _chSize[])
{
    int _size = atoi(_chSize);

    variable* curr = Head ;
    if (firstTimInFunc)
    {
       strcpy(Head->id,_id);
       Head->type = _type ; 
       Head->size = _size;
       firstTimInFunc = false;
       return ;
    }
    while(curr->next!=NULL)
    {
        if(!strcmp(curr->id,_id))
        {
            printf("error the variable %s is allredy exist",_id);
            exit(EXIT_FAILURE);
        }
        curr = curr->next; 
    }
    if(!strcmp(curr->id,_id))
        {
            printf("error the variable %s is allredy exist",_id);
            exit(EXIT_FAILURE);
        }
    variable*  newNode = (variable*)malloc(sizeof(variable));
    if(newNode==NULL)
    {
        printf("couldn't allocate new node");
        exit(EXIT_FAILURE);
    }
    strcpy(newNode->id,_id);
    newNode->type = _type ;
    newNode->size = _size;  
    newNode->next = NULL ;
    curr->next = newNode ;
}

variable * getNodeById(char _id[])
{
    printf("getNodeById\n");
    if(!strcmp(Head->id,_id))
         return Head;

    variable* curr = Head ;
    
    while(curr->next!=NULL)
    {
        if(!strcmp(curr->id,_id))
           return curr;
        curr = curr->next; 
    }
    if(!strcmp(curr->id,_id))
           return curr;
    printf("The variable %s wasn't defined (not found) ",_id);
    exit(EXIT_FAILURE);
}





void yyerror (char *s) {fprintf (stderr, "%s\n", s);}




