.ps.new:{ .msg.makeMsg(`classes`precalc`features`model!(`$();(`$())!();{[seq;i;res]};::)),x};
.ps.calc:{[ps;seq] .ps.calc1[ps;seq]/[();til count seq]};
.ps.calc1:{[ps;seq;res;i]
  if[f:(el:seq i) in key p:.msg.getf[ps;`precalc]; t:p el];
  if[not f;
    t:.ps.modelPredict[.msg.getf[ps;`model];.msg.getf[ps;`features][seq;i;res]];
  ];
  : res,enlist (el;t);
 };
.ps.train:{[ps;exs;i]
  .ps.train1[ps;exs] each til i;
  .ps.modelAverage[.msg.getf[ps;`model]];
 };
.ps.train1:{[ps;exs;x] .ps.trainCalc[ps] each (neg count exs)?exs};
.ps.trainCalc:{[ps;seq] .ps.trainCalc1[ps;seq]/[();til count seq]};
.ps.trainCalc1:{[ps;seq;res;i]
  if[f:(el:seq[0]i) in key p:.msg.getf[ps;`precalc]; t:p el];
  if[not f;
    t:.ps.modelPredict[m:.msg.getf[ps;`model];fea:.msg.getf[ps;`features][seq 0;i;res]];
    .ps.modelUpdate[m;seq[1]i;t;fea];
  ];
  : res,enlist (el;t);
 };

.ps.mnew:{ .msg.makeMsg(`classes`weights`totals`ts`i!(`$();()!`float$();()!`long$();()!`long$();0)),x};

.ps.modelUpdate:{[m;truth;guess;fea]
  f:{[m;f;c;w;v]
    p:(f;c); n:.msg.name m;
    .[n;(`total;p);+;w*(i:.msg.getf[m;`i])-0^.msg.getf[m;`ts]p];
    .[n;(`ts;p);:;i];
    .[n;`weights,p;+;w+v];
  };
  .msg.setf[m;1+.msg.getf[m;`i]];
  if[truth=guess;:()];
  / init weights
  f[;truth;.msg.getf[m;`weights][truth];1.0] each fea;
  f[;guess;.msg.getf[m;`weights][guess];-1.0] each fea;
 };

 def predict(self, features):
         '''Dot-product the features and current weights and return the best label.'''
         scores = defaultdict(float)
         for feat, value in features.items():
             if feat not in self.weights or value == 0:
                 continue
             weights = self.weights[feat]
             for label, weight in weights.items():
                 scores[label] += value * weight
         # Do a secondary alphabetic sort, for stability
         return max(self.classes, key=lambda label: (scores[label], label))

 def average_weights(self):
         '''Average weights from all iterations.'''
         for feat, weights in self.weights.items():
             new_feat_weights = {}
             for clas, weight in weights.items():
                 param = (feat, clas)
                 total = self._totals[param]
                 total += (self.i - self._tstamps[param]) * weight
                 averaged = round(total / float(self.i), 3)
                 if averaged:
                     new_feat_weights[clas] = averaged
             self.weights[feat] = new_feat_weights
         return None
