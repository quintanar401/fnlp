.pc.new:{ .msg.makeMsg(`classes`predefined`getFeatures`model!(`$();(`$())!();{[seq;i;res]};.pc.mnew())),x};
.pc.calc:{[pc;seq] .pc.calc1[pc;seq]/[();til count seq]};
.pc.calc1:{[pc;seq;res;i]
  if[(el:seq i) in key p:.msg.getf[pc;`predefined]; :res,p el];
  :res,.pc.modelPredict[.msg.getf[pc;`model];.msg.getf[pc;`getFeatures][seq;i;res]];
 };
.pc.train:{[pc;exs;i]
  .pc.modelSetup m:.msg.getf[pc;`model];
  .pc.train1[pc;exs] each til i;
  .pc.modelAverage m;
 };
.pc.train1:{[pc;exs;x] .pc.trainCalc[pc] each (neg count exs)?exs};
.pc.trainCalc:{[pc;seq] .pc.trainCalc1[pc;seq]/[();til count seq]};
.pc.trainCalc1:{[pc;seq;res;i]
  if[(el:seq[0]i) in key p:.msg.getf[pc;`predefined]; :res,p el];
  t:.pc.modelPredict[m:.msg.getf[pc;`model];fea:.msg.getf[pc;`features][seq 0;i;res]];
  .pc.modelUpdate[m;seq[1]i;t;fea];
  : res,t;
 };

.pc.dict:(`u#`$())!();
.pc.mnew:{ .msg.makeMsg(`classes`weights`totals`ts`i!(`$();.pc.dict;.pc.dict;.pc.dict;0)),x};

.pc.modelSetup:{[m]
  n:.msg.name m;
  if[0=c:count n`classes; '"classes are not defined"];
  @[n;`totals`ts`i;:;(.pc.dict;.pc.dict;0)];
  if[count k:key n`weights;
    .[n;(`totals;k);:;v:(count k)#enlist c#0f];
    .[n;(`ts;k);:;v];
  ];
 };

.ps.modelUpdate:{[m;truth;guess;fea]
  n:.msg.name m;
  @[n;`i;:;i:1+n`i];
  if[truth=guess;:()];
  cls:n[`classes]?(truth;guess);
  if[count k:f where not (f:key fea)in key n`weights;
    .[n;(`totals;k);:;v:(count k)#enlist c#0f];
    .[n;(`ts;k);:;v];
    .[n;(`weights;k);:;v];
  ];
  .[n;(`totals;f;cls);+;.[n`weights;(f;cls)]*i-.[n`ts;(f;cls)]];
  .[n;(`ts;f;cls);:;i];
  .[n;(`weights;f;cls 0);+;1f]; .[n;(`weights;f;cls 1);+;-1f];
 };

.pc.modelPredictAll:{[m;fea]
  n:.msg.name m;
  fea:(k where (k:key fea)in key w:n`weights)#fea;
  :desc n[`classes]!{x%sum x:exp x} sum w[key fea]*value fea;
 };
.pc.modelPredict:{[m;fea] first key .pc.modelPredictAll[m;fea]};

.pc.modelAverage:{[m]
  n:.msg.name m;
  @[n;`weights;:;] ((n[`totals]k)+w*i-n[`ts]k:key w:n`weights)%i:n`i;
 };
