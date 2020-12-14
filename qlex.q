.lex.sg:("\t \r";"0123456789";.Q.a,.Q.A;"<>";"+-";",*%&|$?#!~@^"); / multi symbol groups
.lex.sg:.lex.sg,"e._:=/\\\"`'\n"; / 1 symbol groups
.lex.c2g:@[128#0;"j"$.lex.sg;:;1+til count .lex.sg]; / char to group map
/ A - id, B - dead end, C -  sym + :,  EF - numbers,floats,times,dates, KL -strings
.lex.mst:" "vs/:("aeA A ae0._"; ". A ae"; / identifiers
  ". E 0";"0E E 0.:a";"0E F e";"F E +0ae."; / Q lexer doesn't care about the exact form of a number/float/date/stamp, it parses first then checks
  "< B ="; "\\'0:+.=<_,C C :"; / <= and >= and ::::: /: \: ': ....
  "` S ae0.";"S S ae0.:_";"` T :";"T T ae0.:_/"; / symbols and paths
  "\" K *"; "K K *"; "K L \""; "K M \\"; "\" L \""; "\" M \\"; "M K *"; / strings, K-start/middle, L-end, M-\X
  "/ U *";"U U *";"U \n \n"; "/ C :"; / simple comment
  "\tW W \t" / merge ws for convenience
 );
.lex.st:distinct" ",(first each .lex.sg),raze .lex.mst[;1]; / all matrix states, before A - initial states
.lex.mt:{a:.lex.st?y;x[a 0;(a 2;::)"*"in y 2]:first a 1;x}/[count[.lex.st]#enlist til 1+count .lex.sg;.lex.mst];
.lex.s2t:{(!). flip raze(.lex.st?x[;0]),\:'x[;1]}(("aeA";`ident);("0EF";`num);("`ST";`sym);("KLM";`str);("\tW";`ws);("C",:;`specfn);((),"U";`comment);((),"\n";`nl);(",+.:=";`op));
.lex.lex:{flip`tok`txt!(.lex.s2t max each i cut c;(i:where(c:.lex.mt\[0;.lex.c2g x])<.lex.st?"A")cut x)};

.lex.sysfn:distinct `flip`neg`first`reciprocal`where`reverse`null`group`hopen`hclose`string`enlist`count`floor`not`key`distinct`type`value`read0`read1`avg`last`sum`prd`min`max`exit`getenv`abs,
   `in`within`like`bin`ss`insert`wsum`wavg`div,1_key .q;
.lex.cntl:`do`if`while`select`update`delete`exec`from`by;
.lex.op:`$(),/:":+-*%&|^=<>$,#_~!?@.";

.lex.2html:{.lex.2html0[x;"k-line"]};
.lex.2htmlI:{.lex.2html0[x;"k-inline"]};
.lex.2html0:{raze{"<div class='",x,"'>",y,"</div>\n"}[y] each .lex.2htmlLine each (distinct 0,where `nl=x`tok)cut x:.lex.lex x};
.lex.2htmlLine:{raze{$[count x 0;"<span class='",x[0],"'>",x[1],"</span>";x 1]}each{v:.h.xs x`txt; $[`ident=t:x`tok;.lex.2htmlIdent v;t=`comment;("k-simple-comment";v);
  t=`ws;("";(6*count v)#"&nbsp;");t in `specfn`op;("k-operator";v);t=`num;.lex.2htmlNum v;t=`sym;("k-const-sym";v);t=`str;("k-string";v);t=`nl;("";"");("";v)]} each x};
.lex.2htmlIdent:{($[(v:`$x)in .lex.sysfn;"k-keyword-function";(3#x)in(".Q.";".q.";".h.";".o.";".z.");"k-keyword-function";v in .lex.cntl;"k-keyword-control";
  v in `x`y`z;"k-keyword-language";x like ".*";"k-variable";"k-name"];x)};
.lex.2htmlNum:{($[all x in .Q.n;"k-number-int";(x[1]in"wWnN")&("0"=x 0)&count[x]<4;"k-const";any"DZ"in x;"k-number-datetime";":"in x;"k-number-time";2=sum"."=x;"k-number-date";"k-number-float"];x)};
