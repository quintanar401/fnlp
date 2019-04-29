.n.id:0;
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
  if[0b~v1:.n.follow1n[node;ks;one;l 1;l 0;1]; :()];
  if[0b~v2:.n.follow1n[node;ks;one;l 1;l 0;-1]; :()];
  : (!). flip distinct v1,v2;
 };
.n.follow1n{[node;ks;one;l;i;step]
  if[i in (0;-1+count l); :()]; n:.msg.get node;
  if[count v0:(v:l i)0;
    if[not all value[v0] in key ks; :0b];
    if[not all key[v0] in key n; :0b];
    if[not all{any x~/:y}'[n key v0;value ks v0]; :0b];
  ];
  if[count v1:v 1;
    if[not all key[v1] in key n; :0b];
    if[not all{any x~/:y}'[n key v1;value v1]; :0b];
  ];
  .n.follow1l[node;ks;one;l;i+1;step]/[();n`to`from step>0];
 };
.n.follow1l{[node;ks;one;l;i;step;st;lnk]
  if[one&count st; :st];
  if[count v0:(v:l i)1;
    
  ];
 };
