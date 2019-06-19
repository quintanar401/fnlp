.n.id:0;
.n.KB:0#.n;
.n.l2Dict:();
.n.l3Dict:();

.n.new:{
  if[not `key`type in key x; '"bad node: ",.Q.s1 x];
  m:.msg.makeMsg(`value`id`to`from!(();.z.P+.n.id+:1;m;m:([] obj:(); typ:0#`; subType:0#`; name:0#`))),x;
  .msg.setf[m;`to_;` sv .msg.name[m],`to];
  .msg.setf[m;`from_;` sv .msg.name[m],`from];
  :m;
 };
.n.k:{.msg.getf[x;`key]};
.n.v:{.msg.getf[x;`value]};
.n.t:{.msg.getf[x;`type]};
.n.lt:{.msg.getf[x;`to]};
.n.lf:{.msg.getf[x;`from]};
.n.str:{
  s:enlist string[.n.k x],"[",string[.n.t x],":",.Q.s1[.n.v x],"]";
  s,:"  ",/:raze .n.mstr .msg.getf[x;`from];
  :s;
 };
.n.mstr:{raze {s:.n.str x`obj; s[0]:"{",string[x`typ],":",string[x`subType],"}",s 0; s} each x};
/ add a list (node;((trg;param);...)) node->trg1->trg2...
.n.addl:{{.n.add[x] . y; y 0}/[x;y]};
/ add a node: node, target, linkType/params
.n.add:{
  if[-11=type z;z:enlist[`typ]!enlist z];
  if[not z[`typ] in `is`isA`in; '"link type: ",string z`typ];
  z[`obj`name]:(y;n:.msg.name y); m upsert v:(key m)#(0#get m:.msg.getf[x;`from_]),z;
  v[`obj`name]:(x;n:.msg.name x); .msg.getf[y;`to_] upsert v;
 };

/ node, params: find by key: link, `linkTypes`linksSubTypes`keys
.n.find:{.n.xfind[x;y;.n.lf x]};
.n.rfind:{.n.xfind[x;y;.n.lt x]};
.n.xfind:{
  w:(); if[-11=type y; y:enlist[`keys]!enlist y];
  if[`linkTypes in key y; w,:enlist (in;`typ;enlist (),y`linkTypes)];
  if[`linkSubTypes in key y; w,:enlist (in;`subType;enlist (),y`linkSubTypes)];
  if[`keys in key y; w,:enlist (in;(each;.n.k;`obj);enlist (),y`keys)];
  : ?[z;w;();(),`obj];
 };
/ find by next key
.n.f_key:{.n.find[x;enlist[`keys]!enlist y]};
.n.rf_key:{.n.rfind[x;enlist[`keys]!enlist y]};
/ find by link types and next key
.n.f_lkey:{.n.find[x;`linkTypes`keys!(y;z)]};
.n.rf_lkey:{.n.rfind[x;`linkTypes`keys!(y;z)]};
/ node, target - target will become invalid
.n.merge:{
  .msg.getf[x;`to_] upsert l:..n.lt y; .msg.setf[y;`to;0#l]; / merge link into
  .n.updLnk[x;.msg.name y;`from_] each l`obj;
  .msg.getf[x;`from_] upsert m:.n.lf y; .msg.setf[y;`from;0#m]; / join links from
  .n.updLnk[x;.msg.name y;`to_] each m`obj;
 };
.n.updLnk:{[t;nm;k;n] update obj:(count i)#enlist t, name:.msg.name t from .msg.getf[n;k] where name=nm};
/ node, target, target will remain valid
.n.copy:{
  .n.cpLnk[x;.msg.name y;`to_] each l:..n.lt y; .msg.getf[x;`to_] upsert l;
  .n.cpLnk[x;.msg.name y;`from_] each l:..n.lf y; .msg.getf[x;`from_] upsert m;
 };
.n.cpLnk:{[t;nm;k;n] m upsert update obj:(count i)#enlist t, name:.msg.name t from (select from m:.msg.getf[n;k] where name=nm, i=min i)};

/ walks: node -lnks-> trg
.n.follow:{[node;ks;l] .n.follow0[node;enlist[`key]!enlist ks;l;1b]};
.n.follow0:{[node;ks;l;one]
  l:.l.map[l];
  v1:.n.follow1ls[ks;one;l 1;1+l 0;1;();(n:.msg.get node)`from];
  v2:.n.follow1ls[ks;one;l 1;-1+l 0;-1;();n`to];
  : $[count v:distinct v1,v2;(!). flip v;()];
 };
.n.follow1n{[node;ks;l]
  n:.msg.get node;
  / node match
  if[count v0:l 0; if[not all{any x~/:y}'[n key v0;value ks v0]; :0b]];
  if[count v1:v 1; if[not all{any x~/:y}'[n key v1;value v1]; :0b]];
  :$[count v 2;enlist (v 2;.msg.name node);()];
 };
.n.follow1ls{[ks;one;l;i;step;st;lnks] .n.follow1l[ks;one;l;i;step]/[st;lnks]};
.n.follow1l{[ks;one;l;i;step;st;lnk]
  if[one&count st; :st];
  if[not i within (0;-1+count l); :st];
  / "*"/"?" link, try to bypass
  if[(t:(v:l i)0)in`s`q; if[one&count st:.n.follow1l[node;ks;one;l;i+2*step;step;st;lnk]; :st]];
  / check link
  if[count v0:v 1; if[not all (lnk key v0)in'value ks v0; :st]];
  if[count v1:v 2; if[not all (lnk key v1)in'value v1; :st]];
  / check node
  if[0b~res:.n.follow1n[lnk`obj;ks;l i+step]; :st];
  if[one&count st:st,res; :st];
  / "*", "+" links, try to follow as "*"
  if[t in`s`p; if[one&count st:.n.follow1l[ks;one;.[l;(i;0);:;`s];i;step;st;lnk]; :st]];
  : .n.follow1ls[ks;one;l;i+2*step;step;st;.msg.get[lnk`obj]`to`from step>0];
 };

.n.filter:{x where 0<count each x:trim x};
.n.get_kb_node:{[name;not_exists]
  if[name in key .n.KB; if[not_exists;'"Duplicate KB node: ",string name]; :.n.KB name];
  :.n.KB[name]:.n.new `type`key!(`kb;name);
 };
.n.load_kb:{[p;init]
  if[init; .n.KB:0#.n];
  {({[ne;a;l;b] .n.add[.n.get_kb_node[a;ne];.n.get_kb_node[b;0b];l]}'). .l.kbparse x} each .n.filter read0 p;
 };

.n.cfilter:{.n.filter(x?\:"#")#'x};
.n.add_l2dict:{[p] {if[y~"lvl3"; :`.n.l3Dict]; x upsert enlist .l.dparse y; x}/[`.n.l2Dict;.n.cfilter read0 p]};
