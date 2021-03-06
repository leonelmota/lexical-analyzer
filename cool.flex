%option noyywrap
%{
  /*
 *  The scanner definition for COOL.
*/

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
*/
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <string>

void append(char* s, char c){
  int len = strlen(s);
  s[len] = c;
  s[len+1] = '\0';
}

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

#define COOL_SET_ERRMSG(message, ...) do { \
        sprintf(err_message, message, __VA_ARGS__); \
        cool_yylval.error_msg = err_message; \
    } while(0);


char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int comment_depth = 0;
char err_message[160];

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN			<-
LE				<=
%Start COMMENT
%X STRING BLOCK_COMMENT


%%
 /* Skip delimiters  */
[ \t\f\r\v]                     ;
 /* Count lines */
\n  ++curr_lineno; // printf("Line: %i\n", curr_lineno);

[0-9]+  {
    yylval.symbol = inttable.add_string(yytext);
    return (INT_CONST);
}

 /* One line comment */
--.*    ;

 /*
  *  Nested comments
  */

"(*"			{ BEGIN BLOCK_COMMENT; }
"*)"			{
	strcpy(cool_yylval.error_msg, "Unmatched *)");
	return (ERROR);
}

<BLOCK_COMMENT>\n		{ curr_lineno++; }
<BLOCK_COMMENT>"\*)"	{ BEGIN 0; }
<BLOCK_COMMENT><<EOF>>	{
	strcpy(cool_yylval.error_msg, "EOF in comment");
	BEGIN 0; return (ERROR);
}

<BLOCK_COMMENT>.		{}


"{"			{ return '{'; }
"}"			{ return '}'; }
"["			{ return '['; }
"]"			{ return ']'; }
"("			{ return '('; }
")"			{ return ')'; }
"~"			{ return '~'; }
","			{ return ','; }
";"			{ return ';'; }
":"			{ return ':'; }
"+"			{ return '+'; }
"-"			{ return '-'; }
"*"			{ return '*'; }
"/"			{ return '/'; }
"%"			{ return '%'; }
"."			{ return '.'; }
"<"			{ return '<'; }
">"			{ return '>'; }
"="			{ return '='; }
"@"			{ return '@'; }

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{ASSIGN}		{ return (ASSIGN); }
{LE}			{ return (LE); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:class)      return (CLASS);
(?i:else)       return (ELSE);
(?i:fi)         return (FI);
(?i:if)         return (IF);
(?i:in)         return (IN);
(?i:inherits)   return (INHERITS);
(?i:isvoid)     return (ISVOID);
(?i:let)        return (LET);
(?i:loop)       return (LOOP);
(?i:pool)       return (POOL);
(?i:then)       return (THEN);
(?i:while)      return (WHILE);
(?i:case)       return (CASE);
(?i:esac)       return (ESAC);
(?i:of)         return (OF);
(?i:new)        return (NEW);
(?i:not)        return (NOT);
true|false      { yylval.symbol = inttable.add_string(yytext); return (BOOL_CONST); }
=               return (ASSIGN);

[a-z][a-zA-Z0-9_]*  { yylval.symbol = inttable.add_string(yytext); return (OBJECTID); }
[A-Z][a-zA-Z0-9_]*  { yylval.symbol = inttable.add_string(yytext); return (TYPEID); }


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\"          { BEGIN(STRING); strcpy(string_buf,""); }
<STRING>[^\\\"]*    {
                strcat(string_buf, yytext);
                // TODO: lengh testing
            }

<STRING>\\.     {
                switch (yytext[1])
                {
                    case 'b': append(string_buf, '\b'); break;
                    case 't': append(string_buf, '\t'); break;
                    case 'n': append(string_buf, '\n'); break;
                    case 'f': append(string_buf, '\f'); break;
                    default: append(string_buf, yytext[1]);
                }
            }
<STRING>\\$     curr_lineno++;
<STRING>\"      {
                BEGIN(INITIAL);
                yylval.symbol = inttable.add_string(string_buf);
                return (STR_CONST);
            }
 /* TODO: */
<STRING>[^\\\"]$    {
        BEGIN(INITIAL);
        cool_yylval.error_msg = "Unterminated string constant";
        return (ERROR);
    }


.   {
        COOL_SET_ERRMSG( "Invalid character: %s", yytext);
        return (ERROR);
    }


%%
