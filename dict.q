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
.dict.xadd:{[a;k;v] if[not k in key a; @[a;k;:;v]]; a};
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
.dict.entry.s:{.dict.d[x;`s]:$[`s in key d:.dict.d x;d`s;()],v:.tok.pSym each .tok.split y; .dict.padd[x;v]};
.dict.entry.v:{.dict.d[x;`v]:$[`v in key d:.dict.d x;d`v;()],v:.tok.pVerbO each .tok.split y; .dict.padd[x;v]};
.dict.entry.l:{{.dict.ladd[x]. `$.tok.nos trim " "vs y}[x]each .tok.nos trim ";" vs y};

/ Unfold a pattern into all possible variants: x - flags, y - prev res, z - entry
.dict.unfold:{raze .dict.unfoldStart[x;y] each .dict.p z};
.dict.unfoldStart:{
  if[`sym=z 0; :.dict.unfold1[x]/[y;z 1]];
  if[`n=z 0; :.dict.unfoldN[x;y;z]];
  if[`v=z 0; :.dict.unfoldV[x;y;z]];
  '"unexpected";
 };
.dict.unfold1:{$[`opt in last z;y;()],.dict.unfold1_[x;y;z]};
.dict.unfold1_:{
  f:.dict.cross y;
  if[`w=z 0; :f z];
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
/ (`v;verb;subj;dobj;pobjs;flags)
.dict.unfoldV:{
  if[count z 2; y:.dict.unfoldN[x;y;z 2]];
  y:.dict.unfold1[x;y;z 1];
  if[count z 3; y:.dict.unfoldN[x;y;z 3]];
  if[count z 3; y:{.dict.unfold1[x;.dict.cross[y] .dict.W z 1;z 2]}[x]/[y;z 4]];
  :y;
 };

/ x - id
.dict.addPMaps:{.dict.addPMap each key .dict.p};
.dict.addPMap:{.dict.addPMapS[x] each .dict.unfold[`$();();x]};
.dict.addPMapS:{
  trg:$[`w=first y0:y 0;`.dict.pmapW;`.dict.pmapP];
  .dict.addPMapI[x;1_y;$[count i:where y0~/:(.dict.pmapI p:.dict.xadd[trg;k;0#0] k:y0 1)[;0]; p first i; .dict.newPMapI[(trg;(),k);y0]]];
 };
.dict.newPMapI:{.dict.pmapI,:enlist (y;0#0;0#`); .[x 0;x 1;,;n:-1+count .dict.pmapI]; n};
/ x - key, y - patt, z - curr id
.dict.addPMapI:{if[0=count y; :.[`.dict.pmapI;(z;2);,;x]]; v:.z.s[x;1_y;$[count i:where y[0]~/:(.dict.pmapI p:.dict.pmapI[z;1])[;0]; p first i; .dict.newPMapI[(`.dict.pmapI;(z;1));y 0]]];};

/ matching
.dict.match:{[t;i] if[count v:.dict.matchP[t;i],.dict.matchW[t;i]; v:v idesc count each v[;1]]; v};
.dict.matchP:{[t;i] raze .dict.matchI[t;i;"f"$()]each raze value[.dict.pmapP] where 0.3<"f"$key[.dict.pmapP] @\: t i};
.dict.matchW:{[t;i] raze .dict.matchI[t;i;"f"$()]each .dict.pmapW `$t[i]`lword};
.dict.matchI:{[t;i;w;id]
  ti:t i;
  if[`fn=first f:first v:.dict.pmapI id; w1:"f"$f[1] ti];
  if[`w=first f; w1:(0.9 1 ti[`word]~f2`word)*ti[`lword]~(f2:first f 2)`lword];
  if[w1<0.3; :()]; w,:w1;
  :$[count v 1;raze .z.s[t;i+1;w] each v 1;()],$[count v 2;v[2],\:enlist w;()];
 };

.dict.match[.tok.tok "2010.10.10D10:10";0]

/

first (first .dict.p`QTIMESTAMP)1
first first .dict.unfold[`$();();`QTIME]
