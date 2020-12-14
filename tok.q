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
.tok.split:{.tok.nos trim 1_'(where (x=";")&not ({1&x+y}\)(neg x=">")+x="<")cut x:";",x};

/ Extract tags and restore the right text structure
.tok.tags:([] tag:0#`; start:0#0; end:0#0; parent:0#0; params:());
.tok.tagTok1:{[t;idx;r]
  if[null ni:exec first i from t where i>=idx, char in "&<";:(c;r,(idx-c:count t)#t)];
  r:r,t idx+til ni-idx;
  if[(w:raze t[`word]ni+0 1 2)in("&amp;";"&gt;";"&lt;"); c:"&<>"("g"=w 1)+"t"=w 2; :(ni+3;r,enlist t[ni+2],`word`lword`shape`char!(c;c;c:(),c;c))]; / &amp; -> & and etc
  if["/"=t[`char]ni+1; :(neg ni+2;r)]; / </tag>
  if[("&"=w 0)|not t[`is_alpha]ni+1; :(ni+1;r,enlist t ni)]; / weird isolated <
  ti:exec first i from t where i>ni+1, char=">"; pp:.tok.toTxt[t;ni+1;count[t]^ti-1];
  tag:`$ts:lower(pp?" ")#pp; pp:ltrim (count ts)_ pp; p:(`$())!();
  if[null ti; '"> is missing in tag ",ts];
  if[count pp; / parameters
    if[not(all enlist["="]~/:w[;1])&3=count last w:(0N 3)#.tok.nos -4!pp; '"wrong parameters in ",ts]; / name = value is expected
    p:(enlist[`]!enlist pp),(`$w[;0])!@[value;;{'"parameter evaluation in ",x," failed with ",y}ts] each w[;2];
  ];
  if[tag in `code`qul`qqul`qa;
    if[null ci:exec first i from t where i>ti, (">"=next char)&("<"=prev prev char)&("/"=prev char)&lword~\:ts; 'ts," tag is not closed"];
    pp:.tok.toTxt[t;ti;ci-2];
    `.tok.tags upsert enlist`tag`start`end`parent`params!($[tag=`code;`icode`code "\n"in pp;tag];count r;count r;-1;p);
    :(ci+2;r,enlist t[ci+1],`word`lword`shape`char`code!(-1_1_pp;"";"";" ";1b));
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
  .tok.addPTag[tok] each {((0N 2)#x)[;0]}(0,raze exec (start,'1+end) from .tok.tags where parent=-1, not tag in .tok.2htmlInline)_ til count tok;
  :(`start xasc update id:i from .tok.tags;tok);
 };
.tok.addPTag:{{if[count x;update parent:count .tok.tags from `.tok.tags where start in x, parent=-1; `.tok.tags upsert (`p;x 0;last x;-1;(`$())!())]}each y:(0,1+where 1<x[`cr]y)cut y};
/ add: tags, (tag;st;end;params) - return t unchanged if t is not possible
.tok.addTag:{[t;tg]
  ch:(exec id from t where start within tg[1 2], end<start),exec id from t where start within tg[1 2], end within tg[1 2];
  if[0<exec count i from t where not id in ch, (start within (1+tg 1;tg 2))|end within (tg 1;-1+tg 2); :t]; / all tags should either be within or outside the range
  p:-1^first exec id except parent from t where tg[1] within (start;end), tg[2] within (start;end); / invariant: always max 1 parent
  tg:tg[0 1 2],(p;tg 3;tid:count t);
  t:update parent:tid from t where id in ch, parent=p; / update parent
  :t upsert tg;
 };
/ convert tokens back to txt within (is;ie)
.tok.toTxt:{[t;is;ie] $[count t:select word,sp from t where i within (is;ie); raze t[`word],'{@[x;-1+count x;:;""]}t`sp;""]};
.tok.toTxt_:{[t;is;ie] $[count t:select word,sp from t where i within (is;ie); raze t[`word],'t`sp;""]};
.tok.str:{$[10=type x;x;98=type x;.tok.toTxt[x;0;0W];.Q.s1 x]};
.tok.delP:{x[0]:update tag:`nop from x 0 where tag=`p, parent=-1; x};

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
  t:.[t;(-1+count t;`space`sp`cr);:;x[n]`space`sp`cr];
  if[`w in  fl; :(enlist["("],{(`w;`$y`lword;enlist y;x)}[fl] each t;(n+1)_x)];
  txt:.tok.toTxt[t;0;0W];
  :((`ref;`$txt;.[-1#t;(0;`word`lword);:;(txt;txt)];(0#`),fl);(n+1)_x);
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
.tok.pUnfold:{{$[-10=type f:first y;$[count x;raze x,/:\:;::]$["{"=f;raze .tok.pUnfold each enlist each 1_y;enlist each enlist[f],/:.tok.pUnfold 1_y];$[0=count x;enlist;x,\:]enlist y]}/[();x]};
.tok.pLine:{if[count last r:.tok.pSeq $[10=type x;.tok.tok x;x];'"Unmatched sequence: ",.tok.toTxt[r 1;0;0W]]; .tok.pUnfold r 0};
.tok.pNounDet:{.tok.pNounDet0 each .tok.pLine x};
.tok.pNounDet0:{
  n:.tok.pNoun x;
  if[`w~first first n1:n 1; if[(w:n[1;0;1]) in `a`the`an; n[4],:w; n[1]:1_n 1]];
  if[1<count n1; n[1]:({$[`w=first x;@[x;3;,;`adj];x]}each -1_n1),-1#n1];
  :n;
 };
/ a b c; a <b> <c>; a (b c) d; a in/at/on/of b
.tok.pNoun:{ .tok.pNounAdj[(`n;();();();`$());x]};
.tok.pNounAdj:{[n;l]
  if[0=count l; :n];
  if[-10=type c:(l0:l 0)0;
    if[not c="(";'"unexpected"];
    n2:.tok.pNounAdj[(`n;();();();`$());1_l0];
    :.tok.pNounAdj[$[()~n2 1;@[n;2 3;,;n2 2 3];@[n;1;,;n2 1]];1_l];
  ];
  if[`w=c;
    if[`of=l0 1; n[2],:enlist .tok.pNounDet0 1_l; :n];
    if[l0[1]in `at`in`on; n[3],:enlist (`pobj;l0 1;.tok.pNounDet0 1_l); :n];
    n[1],:enlist l0; :.tok.pNounAdj[n;1_l];
  ];
  if[`ref=c; n[1],:enlist l0; :.tok.pNounAdj[n;1_l]];
  '"unexpected";
 };
.tok.pVerbO:{.tok.pVerbO0 each .tok.pLine x;};
.tok.pVerbO0:{[l]
  v:first l;
  if[-10=type first l0:l 1;
    o:.tok.pNounDet0 1_l0;
    p:.tok.pVerbP 2_l;
    :(`v;v;();o;p;`$());
  ];
  :(`v;v;();.tok.pNounDet 1_l;();`$());
 };
.tok.pVerbP:{[l]
  if[-10=type first l0:l 0;
    if[not `w~first l0 1; '"Bad pobj fmt: ",.tok.str l];
    if[not (p:l0[1;1]) in `at`on`in`of; '"Bad pobj fmt: ",.tok.str l];
    :enlist[(`pobj;p;.tok.pNounDet0 2_l0;`$())],.tok.pVerbP 1_l;
  ];
  if[not `w~first l0; '"Bad pobj fmt: ",.tok.str l];
  if[not l0[1] in `at`on`in`of; '"Bad pobj fmt: ",.tok.str l];
  :enlist (`pobj;l0 1;.tok.pNounDet0 1_l;`$());
 };
.tok.pSym:{(`sym;;`$())each .tok.pLine x};

/ tags + tokens -> html
.tok.2htmlMap:`nop`top!2#{x`str};
.tok.2htmlMap[`p]:{"<p ",x[`prm],">",x[`str],"</p>\n"};
.tok.2htmlMap[`table]:{"<table class='table'>\n",x[`str],"\n</table>\n"};
.tok.2htmlMap[`qul]:{
  tmpl:$[`tmpl in key p:x`params;p`tmpl;"$nn - $hh"];
  v:{ hhRef:$[x like "*$nn*";{x};.tok.2htmlRef y];
      "<li>",$[not y in key .dict.d;"Unknown entry",string y;ssr[;"$nn";.tok.2htmlRef[y;.h.xs v 0]] ssr[x;"$hh";hhRef (v:.dict.getDescr y)1]],"</li>\n"
    }[tmpl] each asc $[`qul in key x;x`qul;`$.tok.nos " " vs x[`tok][`word] x`start];
  :"<ul>",raze[v],"</ul>";
 };
.tok.2htmlMap[`qqul]:{
  if[not 11=type v:(),@[value;x[`tok][`word] x`start;0]; :"<p>Wrong Q expression in qqul.</p>"];
  if[0=count v; :"<p>Nothing found.</p>"];
  :.tok.2htmlMap[`qul] x,enlist[`qul]!enlist v;
 };
.tok.2htmlRef:{"<a href='#blank'>",y,"</a>"};
.tok.2htmlMap[`ref]:{$[`=id:(x`params)`id;x`str;.tok.2htmlRef[id;x`str]]};
.tok.2htmlCode:{raze{"<div class='",x,"'>",ssr[.h.xn x;" ";"&nbsp;"],"</div>\n"}each "\n" vs y};
.tok.2htmlMap[`code`icode]:{s:`q^lower $[`src in key p:y`params;`$p`src;`q]; $[s=`q;.lex.2html0;.tok.2htmlCode][x;y[`tok][`word] y`start]}@\:("k-line";"k-inline");
.tok.2htmlInline:`b`a`qa`icode;
.tok.2html:{[tag;tok] .tok.2htmlTag[tag;tok;`tag`start`end`id`params!(`top;0;0W;-1;(`$())!())]};
.tok.2htmlTag:{[tag;tok;ptag]
  tg:select from tag where parent=ptag`id, start within ptag`start`end;
  str:{[tg;tk;str;t] str,(.h.xs .tok.toTxt_[tk;t`pend;-1+t`start]),.tok.2htmlTag[tg;tk;t]}[tag;tok]/["";update pend:ptag[`start]^1+prev end from tg];
  str,:.h.xs .tok.toTxt_[tok;ptag[`start]^1+last tg`end;ptag`end];
  prm:$[count prm:ptag`params;" ",prm`;""];
  :$[(t:ptag`tag)in key .tok.2htmlMap; .tok.2htmlMap[t] ptag,`tok`str`prm!(tok;str;prm);"<",t,prm,">",str,"</",(t:string t),">",$[t in .tok.2htmlInline;"";"\n"]];
 };

\

.tok.tok string .Q.chk
.tok.tok "Cat Loves\n\n you"

last .tok.tagTok[.tok.tok "a b&amp;&gt;c"]
{.tok.2html[x 0;x 1]} .tok.tagTok[.tok.tok "aa<a v=1 b=\"aa\">a<b>b</b> c</a>d<cc></cc><cc>cc</cc> xx"]
.tok.tagTok[.tok.tok "b<code> a<a> </code> d"])`start
.tok.pNounDet .tok.tok "<w|b c> a"

W
