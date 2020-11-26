.tok.init:{[p]
  .tok.adj:(`$raze " "vs/:read0 ` sv p,`adj.txt)except`;
  .tok.adj_irr:{x[;0]!1_'x}`$" "vs/:read0 ` sv p,`adj_irr.txt;
  .tok.adv:(`$raze " "vs/:read0 ` sv p,`adv.txt)except`;
  .tok.adv_irr:{x[;0]!1_'x}`$" "vs/:read0 ` sv p,`adv_irr.txt;
  .tok.non:(`$raze " "vs/:read0 ` sv p,`non.txt)except`;
  .tok.non_irr:{x[;0]!1_'x}`$" "vs/:read0 ` sv p,`non_irr.txt;
  .tok.non_all:`u#distinct .tok.non,raze//[key[.tok.non_irr],value .tok.non_irr];
  .tok.ver:(`$raze " "vs/:read0 ` sv p,`ver.txt)except`;
  .tok.ver_irr:{x[;0]!1_'x}`$" "vs/:read0 ` sv p,`ver_irr.txt;
 };

.tok.adj_rules:(("*er";"";"e");("*est";"";"e"));
.tok.non_rules:(("*s";"");("*ses";"s");("*ves";"f");("*xes";"x");("*zes";"z");("*ches";"ch");("*shes";"sh");("*men";"man");("*ies";"y"));
.tok.ver_rules:(("*s";"");("*ies";"y");("*es";"e";"");("*ed";"e";"");("*ing";"e";""));

.tok.check_rule:{[d;r;v] $[count r:r where v like/:r[;0];$[any i:(v:raze`$((1+neg count each r[;0])_\:v),/:'1_'r)in d;v first where i;`];`]};
.tok.check_rule2:{[r;v] $[count r:r where v like/:r[;0];`$((1+neg count r 0)_v),(r:r 0)1;`]};
.tok.isPl:{
  if[((w:`$x)in .tok.non_all)|not null r:.tok.check_rule[.tok.non;.tok.non_rules;x]^first .tok.non_irr `$x;:r];
  :.tok.check_rule2[.tok.non_rules;x];
 };

/ level 1 tokenizer
.tok.tmap:@[;;:;]/[til 255][(.Q.a,.Q.A;.Q.n;" \t\r\n");500+1 2 3];
.tok.shmap:@[;;:;]/["c"$til 255][(.Q.A;.Q.a;.Q.n);"Xxd"];
.tok.tok:{x:(where (x<500)|differ x:.tok.tmap x)cut x; t:flip`word`space!(x w;(next ii)w:where not ii:503=.tok.tmap x[;0]);
  t:update lword:lower word, shape:.tok.shmap word, is_alpha:501=.tok.tmap word[;0], is_num:502=.tok.tmap word[;0], char:word[;0] from t;
  update is_title:is_alpha&("X"=shape[;0])&1=sum each "X"=shape, sp:{@[count[x]#enlist"";w;:;y w:where x]}[space;x w+1], cr:sum each "\n"=x w+1, code:0b, fl:` from t};
.tok.tok_:{v:.tok.tok x; .[v;(-1+count v;`sp);:;()," "]};
.tok.nos:{x where not x[;0] in " \t\r\n"};
.tok.split:{.tok.nos trim 1_'(where (x=";")&not (neg sums 0|x=">")+1&sums x="<")cut x:";",x};

/ Extract tags and restore the right text structure
.tok.tags:([] tag:0#`; start:0#0; end:0#0; parent:0#0; params:());
.tok.tagTok1:{[t;idx;r]
  if[null ni:exec first i from t where i>=idx, char in "&<";:(c;r,(idx-c:count t)#t)];
  r:r,t idx+til ni-idx;
  if[(w:raze t[`word]ni+0 1 2)in("&amp;";"&gt;";"&lt;"); c:"&<>"("g"=w 1)+"t"=w 2; :(ni+3;r,enlist t[ni+2],`word`lword`shape`char!(c;c;c:(),c;c))]; / &amp; -> & and etc
  if["/"=t[`char]ni+1; :(neg ni+2;r)]; / </tag>
  if[("&"=w 0)|not t[`is_alpha]ni+1; :(ni+1;r,enlist t ni)]; / weird isolated <
  ti:exec first i from t where i>idx+1, char=">"; pp:.tok.toTxt[t;ni+1;count[t]^ti-1];
  tag:`$ts:lower(pp?" ")#pp; pp:ltrim (count ts)_ pp; p:(`$())!();
  if[null ti; '"> is missing in tag ",ts];
  if[count pp; / parameters
    if[not(all enlist["="]~/:w[;1])&3=count last w:(0N 3)#.tok.nos -4!pp:.tok.toTxt[t;ni+2;ti-1]; '"wrong parameters in ",ts]; / name = value is expected
    p:(enlist[`]!enlist pp),(`$w[;0])!@[value;;{'"parameter evaluation in ",x," failed with ",y}ts] each w[;2];
  ];
  if[tag=`code;
    if[null ci:exec first i from t where i>ti, (">"=next char)&("<"=prev prev char)&("/"=prev char)&lword~\:"code"; '"code tag is not closed"];
    / `.tok.tags upsert enlist`tag`start`end`parent`params!(tag;count r;count r;0;p);
    :(ci+2;r,enlist t[ci+1],`word`lword`shape`char`code!(-1_1_.tok.toTxt[t;ti;ci-2];"";"";" ";1b));
  ];
  ci:count .tok.tags;
  w:.tok.tagTokIter[t;ti+1;.tok.updR[t ti;`sp`cr;(,;+);r]];
  if[0<w 0; '"tag is not closed: ",ts];
  idx:exec first i from t where i>neg w 0, char=">"; pp:.tok.toTxt[t;neg w 0;count[t]^idx-1];
  if[(null idx)|not tag=`$pp; '"tag ",ts," is improperly closed with ",20 sublist pp];
  update parent:count .tok.tags from `.tok.tags where i>=ci, parent=-1;
  `.tok.tags upsert enlist`tag`start`end`parent`params!(tag;count r;-1+count w 1;-1;p);
  :(idx+1;.tok.updR[t idx;`sp`cr;(,;+);w 1]);
 };
.tok.updR:{[t;cl;f;r] if[not count r; :r]; .[;;;]/[r;(-1+count r;)each cl;f;t cl]};
.tok.tagTokIter:{[t;idx;r] (.tok.tagTok1[t].)/[{y[0]within x}(0;-1+count t);(idx;r)]};
/ tokenize and extract tags -> (tags;tokens)
/ tags: start + end into tokens (end>start = empty tag), parent -> to reflect the tree structure
/ <code> is a special tag that gets folded into 1 token with code=1b
.tok.tagTok:{[t]
  .tok.tags:0#.tok.tags;
  tok:last .tok.tagTokIter[$[10=type t;.tok.tok t;t];0;()];
  {if[count x;`.tok.tags upsert (`p;x 0;last x;-1;(`$())!())]} each {((0N 2)#x)[;0]}(0,raze exec (start,'1+end) from .tok.tags where parent=-1)_ til count tok;
  :(`start xasc update id:i from .tok.tags;tok);
 };
/ convert tokens back to txt within (is;ie)
.tok.toTxt:{[t;is;ie] $[count t:select word,sp from t where i within (is;ie); raze t[`word],'{@[x;-1+count x;:;""]}t`sp;""]};
.tok.str:{$[10=type x;x;98=type x;.tok.toTxt[x;0;0W];.Q.s1 x]};

/ sentence
/ <reference_to_x> - instead of words, <flags|ref_to_x> - extention
/ ref: (`ref;`ref_name;tokens;flags); flags: s - text, f - function, w - words, opt - opional
/ word: (`w;word;token(s);flags)
/ noun: (`n;main;possesive;obj;flags)
/ obj: (`pobj;prep;rest;flags)
/ verb: (`v;verb;subj;dobj;pobjs;flags)
/ sym: (`sym;tlist;flags)
.tok.pRef:{
  if[count[x]=n:x[`char]?">";'"missing >:",.tok.toTxt[x;0;0W]];
  if[count[t]>n2:(t:1_n#x)[`char]?"|"; fl:`$.tok.nos" "vs .tok.toTxt[t;0;n2-1]; t:(n2+1)_t];
  t:.[t;(-1+count t;`sp`cr);:;x[n]`sp`cr];
  if[`w in  fl; :(enlist["("],{(`w;`$y`lword;enlist y;x)}[fl] each t;(n+1)_x)];
  :((`ref;`$.tok.toTxt[t;0;0W];t;(0#`),fl);(n+1)_x);
 };
.tok.pBrk:{
  c:x[`char]0; r:.tok.pSeq 1_x;
  if[not c=(")]}"!"([{")(x:r 1)[`char]0; '"Unmatched ",c,":",.tok.toTxt[x;0;0W]];
  :(enlist[c],r 0;1_x);
 };
.tok.pSeq:{r:.tok.pOne/[(();x)]; (r 0;r 1)};
.tok.pOne:{
  if[0=count t:x 1; :x];
  r:$[(c:t[`char]0)in"([{"; .tok.pBrk t;c="<";.tok.pRef t;c in ")]}";:x;((`w;`$t[0]`lword;1#t;`$());1_t)];
  :(x[0],enlist r 0;r 1);
 };
.tok.pLine:{if[count last r:.tok.pSeq $[10=type x;.tok.tok x;x];'"Unmatched sequence: ",.tok.toTxt[r 1;0;0W]]; r 0};
.tok.pNounDet:{
  n:.tok.pNoun x;
  if[`w~first first n 2; if[(w:n[2;0;1]) in `a`the`an; n[4],:w; n[1]:1_n 1]];
  :n;
 };
/ a b c; a <b> <c>; a (b c) d; a in/at/on/of b
.tok.pNoun:{ .tok.pNounAdj[(`n;();();();`$());$[0=type x;x;.tok.pLine x]]};
.tok.pNounAdj:{[n;l]
  if[0=count l; :n];
  if[-10=type c:(l0:l 0)0;
    if[not c="(";'"unexpected"];
    n2:.tok.pNounAdj[(`n;();();();`$());1_l0];
    :.tok.pNounAdj[$[()~n2 1;@[n;2 3;,;n2 2 3];@[n;1;,;enlist n2 1]];1_l];
  ];
  if[`w=c;
    if[`of=l0 1; n[2],:enlist .tok.pNounDet 1_l; :n];
    if[l0[1]in `at`in`on; n[3],:enlist (`pobj;l0 1;.tok.pNounDet 1_l); :n];
    n[1],:enlist l0; :.tok.pNounAdj[n;1_l];
  ];
  if[`ref=c; n[1],:enlist l0; :.tok.pNounAdj[n;1_l]];
  '"unexpected";
 };
.tok.pVerbO:{
  v:first l:.tok.pLine x;
  if[-10=type first l0:l 1;
    o:.tok.pNounDet 1_l0;
    p:.tok.pVerbP 2_l;
    :(`v;v;();o;p;`$());
  ];
  :(`v;v;();.tok.pNounDet 1_l;();`$());
 };
.tok.pVerbP:{[l]
  if[-10=type first l0:l 0;
    if[not `w~first l0 1; '"Bad pobj fmt: ",.tok.str l];
    if[not (p:l0[1;1]) in `at`on`in`of; '"Bad pobj fmt: ",.tok.str l];
    :enlist[(`pobj;p;.tok.pNounDet 2_l0;`$())],.tok.pVerbP 1_l;
  ];
  if[not `w~first l0; '"Bad pobj fmt: ",.tok.str l];
  if[not l0[1] in `at`on`in`of; '"Bad pobj fmt: ",.tok.str l];
  :enlist (`pobj;l0 1;.tok.pNounDet 1_l;`$());
 };
.tok.pSym:{(`sym;.tok.pLine x;`$())};

/ tags + tokens -> html
.tok.2htmlMap:enlist[`top]!enlist {x};
.tok.2htmlMap[`p]:{"<p>",x,"</p>\n"};
.tok.2htmlInline:`b`a;
.tok.2html:{[tag;tok] .tok.2htmlTag[tag;tok;`tag`start`end`id`params!(`top;0;0W;-1;(`$())!())]};
.tok.2htmlTag:{[tag;tok;ptag]
  tg:select from tag where parent=ptag`id, start within ptag`start`end;
  str:{[tg;tk;str;t] str,.tok.toTxt[tk;t`pend;-1+t`start],.tok.2htmlTag[tg;tk;t]}[tag;tok]/["";update pend:ptag[`start]^1+prev end from tg];
  str,:.tok.toTxt[tok;ptag[`start]^1+last tg`end;ptag`end];
  prm:$[count prm:ptag`params;" ",prm`;""];
  :$[(t:ptag`tag)in key .tok.2htmlMap; .tok.2htmlMap[t] str;"<",t,prm,">",str,"</",(t:string t),">",$[t in .tok.2htmlInline;"";"\n"]];
 };

\

.tok.tok string .Q.chk
.tok.tok "Cat Loves\n\n you"

last .tok.tagTok[.tok.tok "a b&amp;&gt;c"]
{.tok.2html[x 0;x 1]} .tok.tagTok[.tok.tok "aa<a v=1 b=\"aa\">a<b>b</b> c</a>d<cc></cc><cc>cc</cc> xx"]
.tok.tagTok[.tok.tok "b<code> a<a> </code> d"])`start
.tok.pNounDet .tok.tok "<w|b c> a"

W
