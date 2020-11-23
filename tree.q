/ (parent;child idx;child main channel;main;is_leaf;other channels...)

/ x - main value, y - optonal additional channels with default values
.tree.create:{enlist each (0;`long$();0#x;x;0#0b),y};

/ add/overwrite. x - tree, y - path, z - data channels or their subset
.tree.add:{.[x;(4+til 1+count z;4,.tree.add1[x]/[0;y]);:;1b,z]};

/ add/update. x - tree, y - path, z - data channels
.tree.upsert:{.[x;(5+til count z;i:.tree.add1[x]/[0;y]);,;z]; .[x;(4;i);:;1b]};

.tree.add1:{$[count[x[2;y]]=i:x[2;y]?z;.tree.addCh[x;y;z];x[1;y]i]};
.tree.addCh:{.[x;(1 2;y);,;(c:count x 0;z)]; @[x;::;,;(y;`long$();0#z;z),4_x[;0]]; if[1000<count x2:x[2;y]; if[`=attr x2;.[x;(2;y);:;`u#x2]]]; c};

.tree.get1:{$[count[c]=i:(c:x[2;y])?z;0N;x[1;y]i]};
.tree.getAll:{{$[null e:.tree.get1[x;z 0;y i:z 1];z;(e;i+1)]}[get x;(),y]\[(0;z)]};

/ x - tree, y - index
.tree.getIdxPath:{reverse -1_x[0]\[y]};

/ x - tree, y - unrooted path, z - index in y
.tree.matchAt:{i:.tree.getAll[x;y;z]; last where x[5] i[;0]};

/ x - tree,
.tree.findAll:{if[count[y]<>-1+count i:.tree.getAll[x;y;z]; x[3] .tree.getIdxPath[x] each asc raze {raze x y}[x 1]\[1#last i]};
