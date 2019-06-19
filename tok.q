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
