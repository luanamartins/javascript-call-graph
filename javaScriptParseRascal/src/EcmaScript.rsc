module EcmaScript

import ParseTree;
import IO;
import vis::Figure;
import vis::ParseTree;
import vis::Render;
import String;

/*
 * TODO
 * - Check for newlines in continue Id etc.
 * - Do semicolon insertion right.
 */

start syntax Source 
  = SourceElement*
  ;

syntax SourceElement
  = stat:Statement
  | FunctionDeclaration
  ;

syntax FunctionDeclaration 
  = "function" Id "(" {Id ","}* ")" "{" SourceElement* "}"
  ;

syntax ExpressionNoIn // inlining this doesn't work.
  = Expression!inn
  ;

syntax NoCurlyOrFunction 
  = () !>> [{] !>> [f][u][n][c][t][i][o][n]
  ; 

syntax NoElse
  = () !>> [e][l][s][e]
  ;

syntax VariableDeclaration 
  = Id "=" Expression!comma
  | Id
  ;

syntax VariableDeclarationNoIn
  = Id "=" Expression!inn
  | Id
  ;

syntax CaseBlock 
  = "{" CaseClause* DefaultClause? CaseClause* "}"
  ;

syntax CaseClause 
  = "case" Expression ":" Statement*
  ;

syntax DefaultClause 
  = "default" ":" Statement*
  ;

// TODO: should be copied/ renaming Expression to ExpressionNoIN
// and removing instanceof.


syntax Elts
  = ","*
  | ","* Expression ","+ Elts
  | Expression
  ;
  
// Commas (Expression Comma+)* Expression?
// missed case in parsergen.

syntax Expression
  = "this"
  | Id
  | Literal
  | bracket "(" Expression ")"
  | "[" Elts  "]"
  | "{" {PropertyAssignment ","}+ "," "}"
  | "{" {PropertyAssignment ","}* "}"
  > function: "function" Id? "(" {Id ","}* ")" "{" SourceElement* "}"
  | Expression "(" { Expression!comma ","}* ")"
  | Expression "[" Expression "]"
  | Expression "." Id
  > "new" Expression
  > Expression !>> [\n\r] "++" 
  | Expression !>> [\n\r] "--"
  > "delete" Expression
    | "void" Expression
    | "typeof" Expression
    | "++" Expression
    | "--" Expression
    | "+" !>> [+=] Expression
    | "-" !>> [\-=] Expression
    | "~" Expression
    | "!" !>> [=] Expression
  > 
  left ( 
    Expression "*" !>> [*=] Expression
    | Expression "/" !>> [/=] Expression
    | Expression "%" !>> [%=] Expression
  )
  >
  left ( 
    Expression "+" !>> [+=] Expression
    | Expression "-" !>> [\-=] Expression
  )
  >  // right???
  left (
    Expression "\<\<" Expression
    | Expression "\>\>" Expression
    | Expression "\>\>\>" Expression
  )
  >
  non-assoc (
    Expression "\<" Expression
    | Expression "\<=" Expression
    | Expression "\>" Expression
    | Expression "\>=" Expression
    | Expression "instanceof" Expression
    | inn: Expression "in" Expression // remove in NoIn Expressions
  )
  >
  right (
      Expression "===" Expression
    | Expression "!==" Expression
    | Expression "==" !>> [=] Expression
    | Expression "!=" !>> [=] Expression
  )
  > right Expression "&" !>> [&=] Expression
  > right Expression "^"  !>> [=] Expression
  > right Expression "|" !>> [|=] Expression
  > right Expression "&&" Expression
  > right Expression "||" Expression
  > Expression "?" Expression ":" Expression
  > right (
      Expression "=" !>> ([=][=]?) Expression
    | Expression "*=" Expression
    | Expression "/=" Expression
    | Expression "%=" Expression
    | Expression "+=" Expression
    | Expression "-=" Expression
    | Expression "\<\<=" Expression
    | Expression "\>\>=" Expression
    | Expression "\>\>\>=" Expression
    | Expression "&=" Expression
    | Expression "^=" Expression
    | Expression "|=" Expression
  )
  > right comma: Expression "," Expression
  ;


syntax PropertyName
 = Id
 | String
 | Numeric
 ;

syntax PropertyAssignment
  = PropertyName ":" Expression
  | "get" PropertyName "(" ")" "{" FunctionBody "}"
  | "set" PropertyName "(" Id ")" "{" FunctionBody "}"
  ;


syntax Literal
 = "null"
 | Boolean
 | Numeric
 | String
 | RegularExpression
 ;

syntax Boolean
  = "true"
  | "false"
  ;

syntax Numeric
  = [a-zA-Z$_0-9] !<< Decimal
  | [a-zA-Z$_0-9] !<< HexInteger
  ;

lexical Decimal
  = DecimalInteger [.] [0-9]* ExponentPart?
  | [.] [0-9]+ ExponentPart?
  | DecimalInteger ExponentPart?
  ;

lexical DecimalInteger
  = [0]
  | [1-9][0-9]*
  !>> [0-9]
  ;

lexical ExponentPart 
  = [eE] SignedInteger
  ;

lexical SignedInteger 
  = [+\-]? [0-9]+ 
  !>> [0-9]
  ;

lexical HexInteger 
  = [0] [Xx] [0-9a-fA-F]+ 
  !>> [a-zA-Z_]
  ;

lexical String 
  =  [\"] DoubleStringChar* [\"]
  |  [\'] SingleStringChar* [\']
  ;

lexical DoubleStringChar
  = ![\"\\\n]
  | [\\] EscapeSequence
  | LineContinuation
  ;

lexical SingleStringChar
  = ![\'\\\n]
  | [\\] EscapeSequence
  | LineContinuation
  ;

lexical LineContinuation
  = [\\][\\] LineTerminatorSequence
  ;

lexical EscapeSequence 
  = CharacterEscapeSequence
  | [0] !>> [0-9]
  | HexEscapeSequence 
  | UnicodeEscapeSequence
  ;

lexical CharacterEscapeSequence
  = SingleEscapeCharacter
  | NonEscapeCharacter
  ;

lexical SingleEscapeCharacter
  = [\'\"\\bfnrtv]
  ;

lexical NonEscapeCharacter
  = ![\n\"\\bfnrtv]
  ;

lexical EscapeCharacter
  = SingleEscapeCharacter
  | [0-9]
  | [xu]
  ;
  
lexical HexDigit
  = [a-fA-F0-9]
  ;

lexical HexEscapeSequence
  = [x] HexDigit
  ;

syntax UnicodeEscapeSequence
  = "u" HexDigit HexDigit HexDigit HexDigit
  ;

lexical RegularExpression
  = [/] RegularExpressionBody [/] RegularExpressionFlags
  ;

lexical RegularExpressionBody 
  = RegularExpressionFirstChar RegularExpressionChar*
  ;

lexical RegularExpressionFirstChar
  = ![*/\[\n]
  | RegularExpressionBackslashSequence
  | RegularExpressionClass
  ;

lexical RegularExpressionChar
  = ![/\[\n]
  | RegularExpressionBackslashSequence
  | RegularExpressionClass
  ;

lexical RegularExpressionBackslashSequence
  = [\\] ![\n]
  ;

lexical RegularExpressionClass 
  = [\[] RegularExpressionClassChar* [\]]
  ;

lexical RegularExpressionClassChar
  = ![\n\]]
  | RegularExpressionBackslashSequence
  ;

lexical RegularExpressionFlags
  = IdPart*
  ;
  
lexical MultLineComment = @category="Comment"  "/*" CommentChar* "*/";
lexical SingleLineComment =  @category="Comment"  "//" ![\n]* [\n];

lexical CommentChar 
  = ![*] 
  | Asterisk 
  ;

lexical Asterisk 
  = [*] !>> [/] 
  ;

lexical Whitespace
  = [\t-\n\r\ ]
  ;

lexical Comment 
  = MultLineComment
  | SingleLineComment
  ;

lexical LAYOUT 
  = Whitespace  
  | Comment
  ;

layout LAYOUTLIST 
  = LAYOUT* 
  !>> [\t-\n\r\ ] 
  !>> "/*" 
  !>> "//" ;

lexical Id 
  = ([a-zA-Z$_0-9] !<< IdStart IdPart* !>> [a-zA-Z$_0-9]) \ Reserved
  ;

lexical IdStart
  = [$_a-zA-Z]
  ; // "\\" UnicodeEscapeSequence

lexical IdPart
  = [a-zA-Z$_0-9]
  ;


keyword Reserved =
    "break" |
    "case" |
    "catch" |
    "continue" |
    "debugger" |
    "default" |
    "delete" |
    "do" |
    "else" |
    "finally" |
    "for" |
    "function" |
    "if" |
    "instanceof" |
    "in" |
    "new" |
    "return" |
    "switch" |
    "this" |
    "throw" |
    "try" |
    "typeof" |
    "var" |
    "void" |
    "while" |
    "with"
    "abstract" |
    "boolean" |
    "byte" |
    "char" |
    "class" |
    "const" |
    "double" |
    "enum" |
    "export" |
    "extends" |
    "final" |
    "float" |
    "goto" |
    "implements" |
    "import" |
    "interface" |
    "int" |
    "long" |
    "native" |
    "package" |
    "private" |
    "protected" |
    "public" |
    "short" |
    "static" |
    "super" |
    "synchronized" |
    "throws" |
    "transient" |
    "volatile" |
    "null" |
    "true" |
    "false"
  ;