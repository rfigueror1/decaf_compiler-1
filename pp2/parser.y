/* File: parser.y
 * --------------
 * Bison input file to generate the parser for the compiler.
 *
 * pp2: your job is to write a parser that will construct the parse tree
 *      and if no parse errors were found, print it.  The parser should
 *      accept the language as described in specification, and as augmented
 *      in the pp2 handout.
 */
%{

/* Just like lex, the text within this first region delimited by %{ and %}
 * is assumed to be C/C++ code and will be copied verbatim to the y.tab.c
 * file ahead of the definitions of the yyparse() function. Add other header
 * file inclusions or C++ variable declarations/prototypes that are needed
 * by your code here.
 */
#include "scanner.h" // for yylex
#include "parser.h"
#include "errors.h"

void yyerror(const char *msg); // standard error-handling routine

%}

/* The section before the first %% is the Definitions section of the yacc
 * input file. Here is where you declare tokens and types, add precedence
 * and associativity options, and so on.
 */

/* yylval
 * ------
 * Here we define the type of the yylval global variable that is used by
 * the scanner to store attribute information about the token just scanned
 * and thus communicate that information to the parser.
 *
 * pp2: You will need to add new fields to this union as you add different
 *      attributes to your non-terminal symbols.
 */
%union {
    int integerConstant;
    bool boolConstant;
    char *stringConstant;
    double doubleConstant;
    char identifier[MaxIdentLen+1]; // +1 for terminating null
    Decl *decl;
    List<Decl*> *declList;

    VarDecl *vardecl;
    FnDecl *fndecl;
    ClassDecl *classdecl;
    InterfaceDecl *interfacedecl;  
    
    Type *simpletype;
    NamedType *namedtype;
    ArrayType *arraytype;
    
    List<NamedType*> *implements;
    List<VarDecl*> *vardecls;
    
    StmtBlock *stmtblock;
    Stmt *stmt;
    IfStmt *ifstmt;
    Stmt *elsestmt;
    ForStmt *forstmt;
    WhileStmt *whilestmt;
    ReturnStmt *rtnstmt;
    BreakStmt *brkstmt;
    PrintStmt *pntstmt;
    List<Stmt*> *stmts;
   
    Expr *expr;
    Expr *optexpr;
    List<Expr*> *exprs;
    
    IntConstant *intconst;
    DoubleConstant *doubleconst;
    BoolConstant *boolconst;
    StringConstant *stringconst;
    NullConstant *nullconst;
}


/* Tokens
 * ------
 * Here we tell yacc about all the token types that we are using.
 * Bison will assign unique numbers to these and export the #define
 * in the generated y.tab.h header file.
 */	
%token   T_Void T_Bool T_Int T_Double T_String T_Class
%token   T_LessEqual T_GreaterEqual T_Equal T_NotEqual T_Dims
%token   T_And T_Or T_Null T_Extends T_This T_Interface T_Implements
%token   T_While T_For T_If T_Else T_Return T_Break
%token   T_New T_NewArray T_Print T_ReadInteger T_ReadLine


%token   <identifier> T_Identifier
%token   <stringConstant> T_StringConstant
%token   <integerConstant> T_IntConstant
%token   <doubleConstant> T_DoubleConstant
%token   <boolConstant> T_BoolConstant


/* Non-terminal types
 * ------------------
 * In order for yacc to assign/access the correct field of $$, $1, we
 * must to declare which field is appropriate for the non-terminal.
 * As an example, this first type declaration establishes that the DeclList
 * non-terminal uses the field named "declList" in the yylval union. This
 * means that when we are setting $$ for a reduction for DeclList or reading
 * $n which corresponds to a DeclList nonterminal we are accessing the field
 * of the union named "declList" which is of type List<Decl*>.
 * pp2: You'll need to add many of these of your own.
 */
%type <declList>      DeclList
%type <decl>          Decl
%type <vardecl>       VarDecl
%type <fndecl>        FnDecl
%type <classdecl>     ClassDecl
%type <interfacedecl> InterfaceDecl
%type <simpletype>    Type
%type <namedtype>     NamedType
%type <arraytype>     ArrayType
%type <declList>      Formals
%type <declList>      Variables
%type <implements>    Implements
%type <implements>    Impl
%type <identifier>    Extend
%type <declList>      Fields
%type <declList>      Prototypes
%type <vardecls>      VarDecls
%type <stmt>          Stmt
%type <stmts>         Stmts
%type <stmtblock>     StmtBlock
%type <elsestmt>      ElseStmt
%type <expr>          Expr
%type <expr>          OptExpr
%type <exprs>         Exprs
%type <intconst>      IntConstant 
%type <boolconst>     BoolConstant
%type <stringconst>   StringConstant
%type <doubleconst>   DoubleConstant
%type <nullconst>     NullConstant

%%
/* Rules
 * -----
 * All productions and actions should be placed between the start and stop
 * %% markers which delimit the Rules section.
 */

/* Postfixes
 * ---------
 * Some of the non terminals in the grammar have one or more post fixed capital
 * letters. These are intentional and have meaning. Each letter corresponds to
 * the following:
 *     P : Plus     (i.e. 'E+', One or more E)
 *     C : Comma    (i.e. ',' , Used in Conjunction with P (PC) to denote 'E+,'
 *                   One or more E separated by commas)
 *     S : Star     (i.e. 'E*', Zero or more E)
 *     O : Optional (i.e. 'E?', Zero or One E. E is optional)
 */

Program   :    DeclList             {
                                      @1;
                                      /* pp2: The @1 is needed to convince
                                       * yacc to set up yylloc. You can remove
                                       * it once you have other uses of @n*/
                                      Program *program = new Program($1);
                                      // if no errors, advance to next phase
                                      if (ReportError::NumErrors() == 0)
                                          program->Print(0);
                                    }
          ;

DeclList  :    DeclList Decl        { ($$ = $1)->Append($2); }
          |    Decl                 { ($$ = new List<Decl*>)->Append($1); }
          ;

Decl      :    VarDecl             
          |    FnDecl                  
          |    ClassDecl
          |    InterfaceDecl
          ;
          
VarDecl   :    Type T_Identifier ';' { $$ = new VarDecl(new Identifier(@2, $2), $1); }           
          ;
        
Type      :    T_Int                 { $$ = new Type("int"); }
          |    T_Double              { $$ = new Type("double"); }
          |    T_Bool                { $$ = new Type("bool"); }
          |    T_String              { $$ = new Type("string"); }
          |    NamedType             
          |    ArrayType
          ;
          
NamedType :    T_Identifier          { $$ = new NamedType($1); }
 		  ;
 		 
ArrayType :    Type T_Dims             { $$ = new ArrayType(@1, $1); }
          ;
          
FnDecl    :    Type T_Identifier '(' Formals ')' StmtBlock
                                     { $$ = new FnDecl($2, $1, $4); 
                                       $$->SetFunctionBody($6); }
          |    T_Void T_Identifier '(' Formals ')' StmtBlock
                                     { $$ = new FnDecl($2, new Type("void"), $4); 
                                       $$->SetFunctionBody($6); }
          ;

Formals   :    Variables  
          |              
          ;
          
Variables :    Variables ',' Type T_Identifier 
                                     { ($$ = $1)->Append(new VarDecl($2, $1)); }
          |    Type T_Identifier     { ($$ = new List<VarDecl*>)->Append(new VarDecl($2, $1); }
          ;
          
ClassDecl :    T_Class T_Identifier Extend Impl '{' Field '}'              
                                     { $$ = new ClassDecl($2, $3, $4, $6); }
          ;

Extend    :    T_Extends NamedType   { $$ = $2; }
          |
          ;
          
Impl      :    T_Implement Implements { $$ = $2; }
          |
          ;
              
Implements :   Implements ',' NamedType 
                                     { ($$ = $1)->Append($3); }
           |   NamedType             { ($$ = new List<NamedType*>)->Append($1); }
           ;                      

Fields     :   Fields Field          { ($$ = $1)->Append($2); }
           |                         { $$ = new List<Decl*>;  }
           ;  

Field      :   VarDecl 
           |   FnDecl
           ;
           
InterfaceDecl : T_Interface T_Identifier '{' Prototypes '}'
                                     { $$ = new InterfaceDecl($2, $4); }
              ;
              
Prototypes : Prototypes Prototype    { ($$ = $1)->Append($2); }
           | Prototype               { ($$ = new List<Decl*>)->Append($1); }
           ;
            
Prototype  : Type T_Identifier '(' Formals ')' ';'
                                     { $$ = new FnDecl($2, $1, $4); 
                                       $$->SetFunctionBody(NULL); }
           | T_Void T_Identifier '(' Formals ')' ';'
                                     { $$ = new FnDecl($2, new Type("void"), $4);
                                       $$->SetFunctionBody(NULL); }
           ;                
           
StmtBlock  : '{' VarDecls Stmts '}'  { $$ = new StmtBlock($2, $3); }
           ;
           
VarDecls   : VarDecls VarDecl        { ($$ = $1)->Append($2);    }
           |                         { $$ = new List<VarDecl*>;  }
           ;

Stmts      : Stmts Stmt              { ($$ = $1)->Append($2); }
           |                         { $$ = new List<Stmt*>;  }
           ;
           
Stmt       : OptExpr ';'           
           | IfStmt
           | WhileStmt
           | ForStmt
           | BreakStmt
           | ReturnStmt
           | PrintStmt
           | StmtBlock
           ;
          
           
IfStmt     : T_If '(' Expr ')' Stmt ElseStmt
                                     { $$ = new IfStmt($3, $5, $6); }
           ;
                                     
ElseStmt   : T_Else Stmt             { $$ = $2; }
           | 
           ;
           
WhileStmt  : T_While '(' Expr ')' Stmt
                                     { $$ = new WhileStmt($3, $5); }
           ;
           
ForStmt    : T_For '(' OptExpr ';' Expr ';' OptExpr ')' Stmt
                                     { $$ = new ForStmt($3, $5, $7, $9); }
           ;
           
ReturnStmt : T_Return OptExpr ';'    { $$ = new ReturnStmt(@1, $2); }
           ;
        
BreakStmt  : T_Break ';'             { $$ = new BreakStmt(@1); }                            
           ;
           
PrintStmt  : T_Print '(' Exprs ')' ';' 
                                     { $$ = new PrintStmt($3); }
           ;
           
Expr       :  AssignExpr          
           |  Constant
           |  LValue
           |  T_This
           |  Call
           |  '(' Expr ')'
           |  ArithmeticExpr
           |  EqualityExpr
           |  RelationalExpr
           |  LogicalExpr
           |  '-' Expr
           |  T_ReadInteger '(' ')'
           |  T_ReadLine '(' ')'
           |  T_New T_Identifier
           |  T_NewArray '(' Expr ',' Type ')'
           ;

AssignExpr     : LValue '=' Expr
               ;
               
ArithmeticExpr : Expr '+' Expr
               | Expr '-' Expr
               | Expr '*' Expr
               | Expr '/' Expr
               | Expr '%' Expr
               ;
               
EqualityExpr   : Expr T_Equal Expr
               | Expr T_NotEqual Expr
               ;
                             
RelationalExpr : Expr '<' Expr
               | Expr T_LessEqual Expr
               | Expr '>' Expr
               | Expr T_GreaterEqual Expr          
               ;
               
LogicalExpr    : Expr T_And Expr
               | Expr T_Or Expr
               ;               
               
Exprs      : Exprs ',' Expr          { ($$ = $1)->Append($3); }
           | Expr                    { ($$ = new List<Expr*>)->Append($1); }
           ; 

OptExpr    : Expr
           | 
           ;
            
LValue     : T_Identifier            { 
           | Expr '.' T_Identifier
           | Expr '[' Expr ']'
           ; 

Call       : T_Identifier '(' Actuals ')' 
           | Expr '.' T_Identifier '(' Actuals ')'
           ;
           
Actuals    : Exprs 
           |
           ;
           
Constant   : T_IntConstant            
           | T_DoubleConstant
           | T_BoolConstant
           | T_StringConstant
           | T_Null
           ;

IntConstant    : T_IntConstant       { $$ = new IntConstant(@1, $1);
               ;
            
DoubleConstant : T_DoubleConstant    { $$ = new DoubleConstant(@1, $1); }
               ;
               
BoolConstant   : T_BoolConstant      { $$ = new BoolConstant(@1, $1); }
               ;
               
StringConstant : T_StringConstant    { $$ = new StringConstant(@1, $1); }
               ;
               
NullConstant   : T_Null              { $$ = new NullConstant(@1); }
               ;
%%

/* The closing %% above marks the end of the Rules section and the beginning
 * of the User Subroutines section. All text from here to the end of the
 * file is copied verbatim to the end of the generated y.tab.c file.
 * This section is where you put definitions of helper functions.
 */

/* Function: InitParser
 * --------------------
 * This function will be called before any calls to yyparse().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the parser (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yydebug that controls whether yacc prints debugging information about
 * parser actions (shift/reduce) and contents of state stack during parser.
 * If set to false, no information is printed. Setting it to true will give
 * you a running trail that might be helpful when debugging your parser.
 * Please be sure the variable is set to false when submitting your final
 * version.
 */
void InitParser()
{
   PrintDebug("parser", "Initializing parser");
   yydebug = false;
}
