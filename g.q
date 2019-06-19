.g.A:();
.g.fext:{if[count w:where differ[0;]1&sums(not{$[x=2;1;x;$["\""=y;0;"\\"=y;2;1];1*"\""=y]}\[0;x])*(neg"}"=x)+"{"=x;ca:count .g.A;.g.A,:a:value each x b:a+til each d:1+w[;1]-a:(w:(0N 2)#w)[;0];x:@[;;:;]/[x;b;d$(string ca+til count a),\:"h"]];x};
.g.val:{{$[(f:first x)in .Q.n;$[-7=type x:value x;[.g.A,:value{"{:(",x,")}"}";"sv"v",/:string x;"h"$-1+count .g.A];x];f="\"";(),value x;f="`";1_x;f in "?!|+*():";f;$[all x in .Q.A;enlist;::]`$x]}each t where not enlist[" "]~/:t:-4!x};
.g.prule:{if[not(-11=type x 0)&":"~x 1;'"rule fmt"]; .g[x 0]:.g.por "|",2_x};
.g.pflt:{not sums(x~\:"(")+-1*prev x~\:")"}; / utility to filter (...) exprs
.g.por:{i:where(x~\:"|")&.g.pflt x; value {"{i:.g.i;\n  ",(";\n  "sv x),";\n  `.g.err}"}{"if[not`.g.err~v:",x," x; :v]; .g.i:i"}each string .g.pand each 1_'i cut x};
.g.pand:{v:1_{x,$["("~first y;.g.por "|",1_-1_y;y]}/[();(where differ .g.pflt x)cut x:"|",x]; value {"{",y,";\n  (",(";"sv"v",/:string 1+til max x),")}"}[s]";\n  "sv .g.pexp'[s:sums(type each first each v)in 10 11 -11 100h;v:(where differ sums not any each v~/:\:"+?*")cut v]};
.g.pval:{if[-5=t:type x;:-1_1_string .g.A x];"if[",$[-11=t;"`.g.err~v:.g.",string[x]," x";11=t;"[v:.g.t[0;.g.i];not .g.t[1;.g.i]~`",string[x 0],"]";10=t;"not(v:.g.t[0;.g.i])~",$[1=count x;{"(),",1_x};::].Q.s1 x;100=t;"`.g.err~v:",string[x]," x";'"unexp"],";:`.g.err]",$[t in -11 100h;"";"; .g.i+:1"]};
.g.pexp:{v:.g.pval y 0; n:"v",string x; if[1=count y;:v,$[-5=type y 0;"";"; ",n,":v"]]; v:"`.g.err~v:{",v,"; v}[x]"; $["?"=y 1;n,":$[",v,";();v]";n,":",$["+"=y 1;"$[",v,";:`.g.err;enlist v]";"()"],"; while[not ",v,";",n,":",n,",enlist v]"]};
.g.e:{.g.prule .g.val .g.fext x};
.g.p:{.g.t:y; .g.i:0; if[(.g.i<>count .g.t 0)|`.g.err~v:.g[x][];'"parse error in ",string[x],", last token ",.Q.s1 .g.t[0;.g.i]]; v};
.g.l:{(x;{$["\""=first x;`STR;x[0]in .Q.n;`NUM;x[0]in".",.Q.a,.Q.A;`NAME;`]}each x:x where not (()," ")~/:x:-4!x)};

g) linkExprs: "-" (linkExpr ("," linkExpr 2)* {:.l.grp enlist[v1],v2})? "-" ">" ("*"|"+"|"?")? {:($[count v5;("*+?"!`s`p`q)first v5;`];v2)}
g) linkExpr: name ":" value {:(v1;v3)} | name {:(`typ;v1)}
g) nodeExps: nodeExp ("," nodeExp 2)* {: .l.grp enlist[v1],v2}
g) nodeExp: name ":" value {:(v1;v3)} | name {:$[.l.isVar v1;(`name;v1);(`key;v1)]}
g) links: name ":" nodeExps (linkExprs nodeExps?)* {:.l.map[v1]:.l.getx enlist[v3],raze v4}
g) value: name | STR {:value value v1} | NUM {:value v1}
g) name: NAME {:`$v1}

g) dentry: dlist ("|" dlist 2)? ":" drules {:(v1;v2;v4)}
g) dlist: ddef ("," ddef 2)* {:enlist[v1],v2}
g) drules: drule ("," drule 2)* {:enlist[v1],v2}
g) ddef: name name name | name {:(v1;`;`)}
g) drule: name (name | "+") name | name {:(v1;`;`)}

g) kbentry: "#"? name ("," name 2)* name name {:(0=count v1;enlist[v2],v3;v4;v5)}

.l.isVar:{$[null x;0b;1=count x:string x;1b;all(1_x)in .Q.n]};
.l.e:{.g.p[`links] .g.l x};
.l.map:0#.l;
.l.grp:{
  w:w where{("."=x 0)&1=sum "."=x:string x} each v1 w:where -11=type each v1:x[;1];
  enlist[$[count w;{`$1_string x} each (!). flip x w;()]],{$[`name in key x;(`name _ x;first x`name);(x;`)]}{x[;1]group x[;0]} x til[count x] except w};
.l.getx:{v:first raze {$[0=count v:x y;();10=type v 0;();`x=v 2;y;()]}[x] each til count x; (v;x)};
.l.dparse:{`defs`checks`rules!.l.dparse1'[@[{.g.p[`dentry] .g.l x};x;{'"l2 entry: ",x,": ",y}x];001b]};
.l.dparse1:{
  if[0=count x;:()];
  x:flip`node1`link`node2!flip x;
  x[`var]: ?[.l.isVar each x`node1;x`node1;?[.l.isVar each x`node2;x`node2;`]];
  : $[y;x;x value group x`var];
 };
.l.kbparse:{@[{.g.p[`kbentry].g.l x};x;{'"kb entry: ",x,": ",y}x]};

/ fmt: (node;link;node;...)
/ node: (dict that needs args;dict with constants;var name)
/ link: (`s`p`q or `;(dict1;dict2))
l) isA: y, .key -is->* -isA-> -is->* x
