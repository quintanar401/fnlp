.dict.p:(`$())!(); / patterns
.dict.tmpl:(`$())!(); / templates
.dict.pp:(`$())!(); / post proc
.dict.d:1#.dict;   / dictionary
.dict.lr.isA:.dict.l.isA:(`$())!(); / links

/ patt fmt first: lword -> ids in I
/ patt I: (word;next;resolved ids)
.dict.pmapI:enlist (::); / internal
.dict.pmapP:()!(); / patterns start
.dict.pmapR:()!(); / recursion start
.dict.pmapW:(0#`)!(); / word start

.dict.padd:{if[-11=type first y; y:enlist y]; .dict.p[x]:$[x in key .dict.p;.dict.p[x],y;y]; .dict.xadd[`.dict.d;x;``id!(::;x)]};
.dict.ladd:{.dict.xadd[;y;(`$())!()]each `.dict.l`.dict.lr; @[` sv `.dict.l,y;x;,;z]; @[` sv `.dict.lr,y;z;,;x]};
.dict.xadd:{[a;k;v] if[not k in key a; @[a;k;:;v]]; a};
.dict.cross:{$[count x;{$[count y;x,\:enlist y;x]}x;{$[count x;enlist enlist x;enlist ()]}]};

.dict.numn:{$[z`is_num;((x=count w)&v within y;v:value w:z`word);(0f;0)]};
.dict.num:{$[y`is_num;(v within x;v:value y`word);(0f;0)]};
.dict.ppVal:{.dict.fromTmpl[x;enlist raze (raze y[`word])`word]};
.dict.ppFirst:{.dict.fromTmpl[x;enlist string y[`val]0]};
.dict.ppGetVal:{ / find value
  v:{r:(); if[`val in key d:.dict.d x;r,:enlist(y;d`val)]; r,:raze .z.s[;y]each .dict.l.is x; r,:raze .z.s[;y+1]each .dict.l.isA x; r}[x;0];
  : last v first idesc v[;0];
 };

.dict.isA:{(any .dict.is[;y]each v)|y in v:.dict.l.isA first x};
.dict.is_isA:{.dict.isA[x;y]|any .z.s[;y] each .dict.l.is first x};
.dict.is:{(any .z.s[;y]each v)|(y=f)|y in v:.dict.l.is f:first x};
.dict.isNoun:{`n in key .dict.d first x};
.dict.links:{raze{if[count l:.dict.l[y]x; :raze{enlist[x],y}'[(string[y]," "),/:string each l;(2#" "),/:/:.dict.links each l]];()}[x]each 1_key .dict.l};

.dict.init:{[p]
  {{if[1=count v:y 1; if[`ref=first v:v 0; if[`f in last v; y:@[y;1;:;enlist @[v;2;{y[0;`word]:string x;y}x]]]]];
    .dict.padd[x;y]; if[count z:trim z;.dict.pp[x]:value z]}'[`$n#'x;.tok.pSym each trim v[;0];(v:"-->" vs/: (1+n:x?\:" ")_'x)[;1]]} .tok.nos trim read0 ` sv p,`patterns.txt;
  .dict.loadTmpl ` sv p,`templates.txt;
  .dict.loadDict ` sv p,`dict.txt;
  .data.load p;
 };
.dict.postInit:{[p] {.dict.match[.tok.tok x;0]} each read0 ` sv p,`values.txt;};

.dict.loadTmpl:{[p] {id:`$(n:x[0]?" ")#x 0; .dict.tmpl[id]:@[x;0;trim n _]} each .tok.nos each trim (where not " "=x[;0])cut x:read0 p};

.dict.loadDict:{.dict.loadDictEntry each .tok.nos each trim (where not " "=x[;0])cut x:read0 x};
.dict.fromTmpl:{
  if[10=type y;y:enlist y];
  if[not x in key .dict.tmpl;'"wrong template: ",string x];
  if[1=count v:.dict.tmpl x; :.dict.fromTmpl[`$v 0;y]];
  v:{ssr/[y;"SARG",/:string reverse 1+til count x;{x[where x in " "]:"_";x}each x]}[reverse y]each v;
  v:{ssr/[y;"ARG",/:string reverse 1+til count x;x]}[reverse y]each v;
  :$[(id:`$v 0)in key .dict.d; id; .dict.loadDictEntry v];
 };
/ entry fmt: key,defs...
/ defs: name value(s)
/ names: n (noun phrases), l (links)
.dict.loadDictEntry:{if[not (id:`$x 0)in key .dict.d; .dict.d[id]:(``id!(::;id))]; {if[y~(::);'"wrong cmd in ",string x]; y[x;z]}[id]'[.dict.entry`$n#'v;trim (1+n:v?\:" ")_'v:1_x]; id};
.dict.entry.n:{.dict.d[x;`n]:$[`n in key d:.dict.d x;d`n;()],v:raze .tok.pNounDet each .tok.split y; .dict.padd[x;v]};
.dict.entry.s:{.dict.d[x;`s]:$[`s in key d:.dict.d x;d`s;()],v:raze .tok.pSym each .tok.split y; .dict.padd[x;v]};
.dict.entry.w:{.dict.d[x;`w]:$[`s in key d:.dict.d x;d`w;()],v:raze .tok.pWord each .tok.split y; .dict.padd[x;v]};
.dict.entry.v:{.dict.d[x;`v]:$[`v in key d:.dict.d x;d`v;()],v:raze .tok.pVerbO each .tok.split y; .dict.padd[x;v]};
.dict.entry.l:{{.dict.ladd[x]. `$.tok.nos trim " "vs y}[x]each .tok.nos trim ";" vs y};
.dict.entry.val:{.dict.d[x;`val]:@[value;y;{'".dict.entry.val for ",string[x]," and ",y," with ",z}[x;y]]};
.dict.entry.look:{.dict.match[.tok.tok y;0]};
.dict.entry.com:{.dict.d[x;`com]:y};

/ Unfold a pattern into all possible variants: x - flags, y - prev res, z - entry
.dict.unfold:{raze .dict.unfoldStart[x;y] each .dict.p z};
.dict.unfoldStart:{
  if[`sym=z 0; :.dict.unfold1[x]/[y;z 1]];
  if[`n=z 0; :.dict.unfoldN[x;y;z]];
  if[`v=z 0; :.dict.unfoldV[x;y;z]];
  '"unexpected";
 };
.dict.unfold1:{.dict.unfold1_[x;y;z],$[`opt in last z;y;()]};
.dict.unfold1_:{
  f:.dict.cross y;
  if[`w=z 0; :f z];
  if[`ref=z 0; :$[`f in fl:last z;f (`fn;value string z 1;z 2;last z);`s in f;f z 2;{@[y;-1+count y;.dict.unfoldSp x]}[last[z 2]`space`sp`cr]each .dict.unfold[x;y;z 1]]];
  if[`n=z 0; :.dict.unfoldN[x;y;z]];
  '"unexpected";
 };
.dict.unfoldSp:{y[2]:.[y 2;(-1+count y 2;`space`sp`cr);:;x];y};
.dict.W:(!). flip {.dict[`$upper x]:v:first first .tok.pSeq .tok.tok_ x; (`$x;v)} each ((),"a";"the";"of";"at";"in";"on");
/ (`n;main;possesive;obj;flags)
.dict.unfoldN:{
  if[count z 1;
    / if[not `noun in x; y:y,raze .dict.cross[y] each (();.dict.A;.dict.THE)];
    y:.dict.unfold1[`noun,x]/[y;z 1]; / main
  ];
  if[count z 2; y:{.dict.unfold1[x;.dict.cross[y] .dict.OF;z]}[x]/[y;z 2]];
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
.dict.addPMap:{.dict.addPMapS[x] each v:.dict.unfold[`$();();x]; if[count v; .dict.d[x;`txt`patt]:(.dict.getDefRepr v 0;raze{$[`fn in x[;0];();enlist .tok.toTxt_[raze x[;2];0;0W]]} each v)]};
.dict.addPMapS:{
  trg:$[`w=first y0:y 0;`.dict.pmapW;`patt in last y0;`.dict.pmapR;`.dict.pmapP];
  .dict.addPMapI[x;1_y;$[count i:where y0~/:(.dict.pmapI p:.dict.xadd[trg;k;0#0] k:y0 1)[;0]; p first i; .dict.newPMapI[(trg;(),k);y0]]];
 };
.dict.newPMapI:{.dict.pmapI,:enlist (y;0#0;0#`); .[x 0;x 1;,;n:-1+count .dict.pmapI]; n};
/ x - key, y - patt, z - curr id
.dict.addPMapI:{if[0=count y; :.[`.dict.pmapI;(z;2);,;x]]; v:.z.s[x;1_y;$[count i:where y[0]~/:(.dict.pmapI p:.dict.pmapI[z;1])[;0]; p first i; .dict.newPMapI[(`.dict.pmapI;(z;1));y 0]]];};
.dict.getPMap:{.dict.pmapI[;0]raze{$[count v:.z.s each where x in/: .dict.pmapI[;1];raze[v],\:x;enlist (),x]}each where x in/: last each .dict.pmapI};
.dict.strPMap:{{raze{$[`fn=x 0;{"{",x,"}"};::] .tok.toTxt_[x 2;0;0W]}each x}each .dict.getPMap x};
.dict.getDefRepr:{.tok.toTxt[;0;0W]raze x[;2] where not {last[x]in -1_x}each{$[not `w=y 0;`$();z;x,`$first y[2]`lword;`$()]}\[`$();x;`adj in/: last each x]};

/ (id;prob;len;steps)
/ steps: (prob; type; word; value)

/ matching
.dict.match:{[t;i]
  if[count v:.dict.matchP[t;i],.dict.matchW[t;i];
    v:v2:.dict.matchPP each v;
    while[count v2:.dict.matchPP each raze {raze .dict.matchR[x;y;z]each til count .dict.pmapR}[t;i] each v2; v,:v2];
    v:v idesc v[;1];
  ];
  :v;
 };
.dict.matchP:{[t;i] raze .dict.matchI[t;i;()]each raze value[.dict.pmapP] where 0.3<"f"$(key[.dict.pmapP] @\: t i)[;0]};
.dict.matchW:{[t;i] raze .dict.matchI[t;i;()]each .dict.pmapW `$t[i]`lword};
.dict.matchR:{[t;i;v;n]
  if[0.3>p:(key[.dict.pmapR] n) v; :()];
  w:enlist(p*v 1;`rec;raze v[3]`word;v);
  r:$[count vv:raze (m:.dict.pmapI[value[.dict.pmapR] n])[;2];vv,\:enlist w;()];
  :$[count vv:raze m[;1]; raze .dict.matchI[t;i+v 2;w]each vv;()],r;
 };
.dict.matchI:{[t;i;w;id]
  ti:t i;
  if[`fn=ty:first f:first v:.dict.pmapI id;
    if[not pat:`patt in last f; w1:"f"$first val:f[1] ti; val:val 1];
    if[pat; ty:`rec; w1:0f; val:.dict.match[t;i]; val[;1]:val[;1]*f[1] each val; if[count val; val:val first idesc val[;1]; w1:val 1; ti:raze val[3]`word]];
  ];
  if[`w=ty; w1:(0.9 1 ti[`word]~f2`word)*ti[`lword]~(f2:first f 2)`lword; val:()];
  if[w1<0.3; :()]; w,:enlist (w1;ty;$[99=type ti;enlist ti;ti]; val);
  :$[count v 1;raze .z.s[t;i+1;w] each v 1;()],$[count v 2;v[2],\:enlist w;()];
 };
.dict.matchPP:{
  v:flip`prob`typ`word`val!flip x 1;
  if[(k:x 0) in key .dict.pp; k:.dict.pp[k][`$string[k],"_templ"] v];
  :(k;sum v`prob;sum count each v`word;v);
 };
.dict.matchAll:{last({if[y>=count x;:(y;z)]; if[0=count v:.dict.match[x;y]; :(y+1;z)]; :(i;z,enlist(y;-1+i:y+v[0] 2;{x x0?distinct x0:x[;0]}{x where x[;2]=x[0;2]} v))}[$[10=type x;.tok.tok x;x]].)/[(0;())]};
.dict.matchAllAndTag:{ (.tok.addTag/[x 0;{(`ref;x 0;x 1;enlist[`ids]!enlist x 2)} each .dict.matchAll last x];last x:$[10=type x;.tok.tagTok x;x])};

.dict.getDescr:{d:.dict.d x; ($[`txt in key d;d`txt;"unknown"];$[`h in key d;.tok.2html . .tok.delP d`h;""];x)};

first .dict.match[.tok.tok "Apr 2010";0]
first .dict.match[.tok.tok "2010 May 20";0]
first .dict.match[.tok.tok "2010-11-20";0]
first .dict.match[.tok.tok "2010/11/20";0]
first .dict.match[.tok.tok "10-11-2020";0]
first .dict.match[.tok.tok "Europe/London";0]
.dict.match[.tok.tok "10";0]
first .dict.matchAllAndTag "10 2010 May 20 april"
first .dict.match[.tok.tok "190.0.0.128";0]
.dict.match[.tok.tok "10pm Europe/London";0]
first .dict.match[.tok.tok string .z.P;0]
.dict.match[.tok.tok "one hundred 3 hundred";0]
.dict.match[.tok.tok "one hundred forty two";0]
.dict.match[.tok.tok "10:30:30 Europe/London";0]
.dict.match[.tok.tok "10:20";0]
.dict.links`$"dt_QMINUTE_10:20"

/
.dict.l[`hasPart]
dt_DATE_2010.11.20
.dict.pmapI 52
first (first .dict.p`MONTHNAME)1
first first .dict.unfold[`$();();`MONTHNAME]
