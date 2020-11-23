.dict.p:(`$())!(); / patterns
.dict.d:1#.dict;   / dictionary
.dict.lr.isA:.dict.l.isA:(`$())!(); / links

/ patt fmt first: lword -> ids in I
/ patt I: (word;next;resolved ids)
.dict.pmapI:enlist (::); / internal
.dict.pmapP:()!(); / patterns start
.dict.pmapW:(0#`)!(); / word start

.dict.padd:{if[-11=type first y; y:enlist y]; .dict.p[x]:$[x in key .dict.p;.dict.p[x],y;y]; .dict.xadd[`.dict.d;x;``id!(::;x)]};
.dict.ladd:{.dict.xadd[;y;(`$())!()]each `.dict.l`.dict.lr; @[` sv `.dict.l,y;x;,;z]; @[` sv `.dict.lr,y;z;,;x]};
.dict.xadd:{[a;k;v] if[not k in key a; @[a;k;:;v]]};
.dict.cross:{$[count x;{$[count y;x,\:enlist y;x]}x;{$[count x;enlist enlist x;enlist ()]}]};

.dict.numn:{$[z`is_num;(x=count w)&value[w:z`word]within y;0]};
.dict.num:{$[y`is_num;value[y`word]within x;0]};

.dict.init:{[p]
  {.dict.padd'[`$n#'x;.tok.pSym each (1+n:x?\:" ")_'x]} .tok.nos trim read0 ` sv p,`patterns.txt;
  .dict.loadDict ` sv p,`dict.txt;
 };

.dict.loadDict:{.dict.loadDictEntry each .tok.nos each trim (where not " "=x[;0])cut x:read0 x};
/ entry fmt: key,defs...
/ defs: name value(s)
/ names: n (noun phrases), l (links)
.dict.loadDictEntry:{if[not (id:`$x 0)in key .dict.d; .dict.d[id]:(``id!(::;id))]; {y[x;z]}[id]'[.dict.entry `$n#'v;trim (1+n:v?\:" ")_'v:1_x]; id};
.dict.entry.n:{.dict.d[x;`n]:$[`n in key d:.dict.d x;d`n;()],v:.tok.pNounDet each .tok.split y; .dict.padd[x;v]};
.dict.entry.l:{{.dict.ladd[x]. `$.tok.nos trim " "vs y}[x]each .tok.nos trim ";" vs y};

/ Unfold a pattern into all possible variants: x - flags, y - prev res, z - entry
.dict.unfold:{raze .dict.unfoldStart[x;y] each .dict.p z};
.dict.unfoldStart:{
  if[`sym=z 0; :.dict.unfold1[x]/[y;z 1]];
  if[`n=z 0; :.dict.unfoldN[x;y;z]];
  '"unexpected";
 };
.dict.unfold1:{
  f:.dict.cross y;
  if[`w=z 0; :f enlist z];
  if[`ref=z 0; :$[`f in fl:last z;f (`fn;value string z 1);`s in f;f z 2;.dict.unfold[x;y;z 1]]];
  if[`n=z 0; :.dict.unfoldN[x;y;z]];
  '"unexpected";
 };
.dict.W:(!). flip {.dict[`$upper x]:v:first first .tok.pSeq .tok.tok_ x; (`$x;v)} each ((),"a";"the";"of";"at";"in";"on");
/ (`n;main;possesive;obj;flags)
.dict.unfoldN:{
  if[count z 1;
    if[not `noun in x; y:y,raze .dict.cross[y] each (();.dict.A;.dict.THE)];
    y:.dict.unfold1[`noun,x]/[y;z 1]; / main
  ];
  if[count z 2; y:{.dict.unfold1[x;.dict.cross[y] .dict.OFF;z]}[x]/[y;z 2]];
  if[count z 3; y:{.dict.unfold1[x;.dict.cross[y] .dict.W z 1;z 2]}[x]/[y;z 3]];
  :y;
 };

/ x - id
.dict.addPMap:{.dict.addPMapS[x] each .dict.unfold[`$();();x]};
.dict.addPMapS:{
  trg:$[`w=first y0:y 0;`.dict.pmapW;`.dict.pmapP];
  .dict.addPMapI[x;1_y;$[count i:where y0~/:(.dict.pmapI p:.dict.xadd[trg;k;0#0] k:p 1)[;0]; p first i; .dict.newPMapI[(trg;(),k);y0]]];
 };
.dict.newPMapI:{.dict.pmapI,:enlist (y;0#0;0#`); .[x 0;x 1;,;n:-1+count .dict.pmapI]; n};
/ x - key, y - patt, z - curr id
.dict.addPMapI:{if[0=count y; :.[`.dict.pmapI;(z;2);,;x]]; v:.z.s[x;1_y;$[count i:where y[0]~/:(.dict.pmapI p:.dict.pmapI[z;1])[;0]; p first i; .dict.newPMapI[(`.dict.pmapI;(z;1));y 0]]];};

/
first (first .dict.p`QTIMESTAMP)1
first first .dict.unfold[`$();();`QTIME]
