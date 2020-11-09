.tok.init:{[p]
  p:p,`data;
  .tok.adj:(`$raze " "vs/:read0 ` sv p,`adj.txt)except`;
  .tok.adj_irr:{x[;0]!1_'x}`$" "vs/:read0 ` sv p,`adj_irr.txt;
  .tok.adv:(`$raze " "vs/:read0 ` sv p,`adv.txt)except`;
  .tok.adv_irr:{x[;0]!1_'x}`$" "vs/:read0 ` sv p,`adv_irr.txt;
  .tok.non:(`$raze " "vs/:read0 ` sv p,`non.txt)except`;
  .tok.non_irr:{x[;0]!1_'x}`$" "vs/:read0 ` sv p,`non_irr.txt;
  .tok.ver:(`$raze " "vs/:read0 ` sv p,`ver.txt)except`;
  .tok.ver_irr:{x[;0]!1_'x}`$" "vs/:read0 ` sv p,`ver_irr.txt;
 };

.tok.adj_rules:(("*er";"";"e");("*est";"";"e"));
.tok.non_rules:(("*s";"");("*ses";"s");("*ves";"f");("*xes";"x");("*zes";"z");("*ches";"ch");("*shes";"sh");("*men";"man");("*ies";"y"));
.tok.ver_rules:(("*s";"");("*ies";"y");("*es";"e";"");("*ed";"e";"");("*ing";"e";""));

.tok.check_rule:{[d;r;v] $[count r:r where v like/:r[;0];$[any i:(v:raze`$((1+neg count each r[;0])_\:v),/:'1_'r)in d;v first where i;`];`]};

.tok.init `:.

.tok.check_rule[.tok.ver;.tok.ver_rules;"copying"]

/ level 1 tokenizer
.tok.tmap:@[;;:;]/[til 255][(.Q.a,.Q.A;.Q.n;" \t\r\n");500+1 2 3];
.tok.shmap:@[;;:;]/["c"$til 255][(.Q.A;.Q.a;.Q.n);"Xxd"];
.tok.tok:{x:(where (x<500)|differ x:.tok.tmap x)cut x; t:flip`word`space!(x w;(next ii)w:where not ii:503=.tok.tmap x[;0]);
  t:update lword:lower word, shape:.tok.shmap word, is_alpha:501=.tok.tmap word[;0], is_num:502=.tok.tmap word[;0], char:word[;0] from t;
  update is_title:is_alpha&("X"=shape[;0])&1=sum each "X"=shape, sp:{@[count[x]#enlist"";w;:;y w:where x]}[space;x w+1], cr:sum each "\n"=x w+1, code:0b from t};
.tok.nos:{x where not x[;0] in " \t\r\n"};
/ Extract tags and restore the right text structure
.tok.tags:([] tag:0#`; start:0#0; end:0#0; parent:0#0; params:());
.tok.tagTok1:{[t;idx;r]
  if[null ni:exec first i from t where i>=idx, char in "&<";:(c;r,(idx-c:count t)#t)];
  r:r,t idx+til ni-idx;
  if[(w:raze t[`word]ni+0 1 2)in("&amp;";"&gt;";"&lt;"); c:"&<>"("g"=w 1)+"t"=w 2; :(ni+3;r,enlist t[ni+2],`word`lword`shape`char!(c;c;c:(),c;c))]; / &amp; -> & and etc
  if["/"=t[`char]ni+1; :(neg ni+2;r)]; / </tag>
  if[not t[`is_alpha]ni+1; :(ni+1;r,enlist t idx)]; / weird isolated <
  tag:`$ts:t[`lword]ni+1; p:(`$())!(); if[null ti:exec first i from t where i>idx+1, char=">"; '"> is missing in tag ",ts];
  if[ti>ni+2; / parameters
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
  if[not(">"=t[`char]idx+1)&tag=`$t[`lword]idx:neg w 0; '"tag ",ts," is improperly closed with ",t[`word] idx];
  update parent:count .tok.tags from `.tok.tags where i>=ci, parent=-1;
  `.tok.tags upsert enlist`tag`start`end`parent`params!(tag;count r;-1+count w 1;-1;p);
  :(idx+2;.tok.updR[t idx+1;`sp`cr;(,;+);w 1]);
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

/ sentence
/ <reference_to_x> - instead of words, <flags|ref_to_x> - extention
/ ref: (`ref;`ref_name;flags)
/ word: (`w;token;flags)
/ noun phrase: a b c of .. in ... - adjectives, nouns + main word c - EMEA stock HDB
/ noun: (`n;main;pre;post;flags) where pre - adj and etc, post - of ..., in ... and etc
.tok.pRef:{
  if[count[x]=n:x[`char]?">";'"missing >:",.tok.toTxt[x;0;0W]];
  if[count[t]>n2:(t:1_n#x)[`char]?"|"; fl:`$.tok.nos" "vs .tok.toTxt[t;0;n2-1]; t:(n2+1)_t];
  :((`ref;`$.tok.toTxt[t;0;0W];(0#`),fl);(n+1)_x);
 };
.tok.pBrk:{
  c:x[`char]0; r:.tok.pSeq 1_x;
  if[not c=(")]}"!"([{")(x:r 1)[`char]0; '"Unmatched ",c,":",.tok.toTxt[x;0;0W]];
  :(@[r 0;0;:;c];1_x);
 };
.tok.pSeq:{r:.tok.pOne/[(();x)]; (enlist[";"],r 0;r 1)};
.tok.pOne:{
  show x 1;
  if[0=count t:x 1; :x];
  r:$[(c:t[`char]0)in"([{"; .tok.pBrk t;c="<";.tok.pRef t;c in ")]}";:x;((`w;1#t;`$());1_t)];
  :(x[0],enlist r 0;r 1);
 };
.tok.pLine:{if[count last r:.tok.pSeq x;'"Unmatched sequence: ",.tok.toTxt[r 1;0;0W]]; r 0};

last .tok.pLine .tok.tok "aa (<pl  ay|ab> aa)"
.tok.pNounDet:{
  fl:();
  if[(w:`$x[`lower]0)in `a`the; fl,:w];
  .tok.pNoun 1_x;
 };
.tok.pNoun:{
  if[(c:x[`char]0)="(";];
 };

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


.tok.tok string .Q.chk
.tok.tok "Cat Loves\n\n you"

last .tok.tagTok[.tok.tok "a b&amp;&gt;c"]
{.tok.2html[x 0;x 1]} .tok.tagTok[.tok.tok "aa<a v=1 b=\"aa\">a<b>b</b> c</a>d<cc></cc><cc>cc</cc> xx"]
.tok.tagTok[.tok.tok "b<code> a<a> </code> d"])`start
.tok.pRef .tok.tok "a_b> a"

W
