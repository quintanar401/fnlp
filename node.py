def find_first(lst,key):
    for l in lst:
        res = l.next(key)
        if res:
            return res
    return None

class Node:
    id = 0
    def __init__(self, key, type, value=None):
        self.key = key
        self.value = value
        self.type = type
        self.links_to = []
        self.links_from = []
        self.id = Node.id
        Node.id += 1
    def str(self):
        return self.key+"["+self.type+","+str(self.value)+"]"
    def __str__(self):
        lnk = ",".join([l.type+"->"+l.to.str() for l in self.links_to])
        return self.str()+"("+lnk+")"
    def __repr__(self):
        return self.__str__()
    def add_to_link(self, lnk):
        self.links_to.append(lnk)
    def add_from_link(self, lnk):
        self.links_from.append(lnk)
    def next(self,key):
        return find_first(self.links_to,key)
    def lnext(self,key):
        for l in self.links_to:
            if l.type == key:
                return l.to
        return None
    def add_node(self,node,ltype,lSubType=None):
        Link(self,ltype,node,subType=lSubType)
        return self

class Link:
    def __init__(self, frm, type, to, subType=None):
        self.frm = frm
        self.type = type
        self.to = to
        self.subType = subType
        frm.add_to_link(self)
        to.add_from_link(self)
    def next(self, key):
        return self.to if self.to.key == key else None

class BaseFNLPException(BaseException):
    def __init__(self,err):
        self.msg = err
class UnknownLinkType(BaseFNLPException):
    pass
class DuplicateKBRef(BaseFNLPException):
    pass

ESTR = re.compile("^\s*$")
ESTR2 = re.compile("^(\s*|\s*#.*)\r?\n?$")

def get_kb_node(name,type="kb",value=None,not_exists=False):
    try:
        nm = KB[name]
        if not_exists:
            raise DuplicateKBRef(name)
        return nm
    except KeyError:
        KB[name] = Node(name,type,value)
        return KB[name]

def load_kb(path, encoding='latin1'):
    global KB
    KB = {}
    with codecs.open(path, encoding=encoding) as f:
        for str in f:
            if ESTR2.match(str):
                continue
            tok = fnlpTok(str)
            if tok[0].text == "#":
                t1, rel, t2, ex = (tok[1].text, tok[2].text, tok[3].text, False)
            else:
                t1, rel, t2, ex = (tok[0].text, tok[1].text, tok[2].text, True)
            if rel == "is":
                Link(get_kb_node(t1, not_exists=ex),"kb",get_kb_node(t2))
            else:
                raise UnknownLinkType(rel)

class Dict:
    def __init__(self, path, encoding='latin1'):
        self.dict = {}
        self.add_dict(path, encoding)
    def add_dict(self, path, encoding='latin1'):
        with codecs.open(path, encoding=encoding) as f:
            for str in f:
                if ESTR2.match(str):
                    continue
                self.add_dict_entry(str.strip("\r\n"))
    def add_dict_entry(self,str):
        toks = []; brk = None; esc = False; i = 0; doc = fnlpTok(str)
        for t in doc:
            i += 1
            if esc:
                esc = False
            elif t.text == "\\":
                esc = True
                continue
            elif t.text in ["'",'"']:
                if brk:
                    break
                brk = t.text
                continue
            ntok = { "word": t.text, "lword": t.text.lower(), "lemma": t.lemma_.lower(), "ws": len(t.whitespace_)>0 }
            toks.append(ntok)
            if (not brk) and ntok["ws"]:
                break
        toks[-1]["ws"] = None
        kbw = [toks[-1]["word"]] if i is len(doc) else [t.text for t in doc[i:]]
        W = self.get_entry(toks[0]["lemma"])
        entry = self.match_exact_entry_tokens(W,toks) if len(W) else None
        if entry:
            kbw = [f for f in filter(lambda x: not any(map(lambda y: y.next(x),entry["ids"])),kbw)]
            entry["ids"] += [Node(t,"word_proxy").add_node(get_kb_node(t),"pointer") for t in kbw]
            return entry["ids"]
        W.append({ "tokens": toks, "ids": [Node(t,"word_proxy").add_node(get_kb_node(t),"pointer") for t in kbw]})
        return W[-1]["ids"]
    def match_exact_entry_tokens(self, entry, tokens):
        for e in entry:
            ent = e["tokens"]
            if not len(ent) is len(tokens):
                continue
            if func.reduce(lambda x,y: x and (ent[y]["word"] == tokens[y]["word"] and ent[y]["ws"] is tokens[y]["ws"]), range(len(tokens)), True):
                return e
        return None

    def __contains__(self, val):
        return val in self.dict

    def __getitem__(self, name):
        return self.dict[name.lower()]

    def get_entry(self, name):
        try:
            return self.dict[name]
        except KeyError:
            self.dict[name] = []
            return self.dict[name]

    def get_repr(self, txt, src, kb_id):
        n = Node(txt,"word_repr").add_node(Node("matches","synt",self.add_dict_entry(txt+" "+kb_id)),"assoc")
        n.add_node(Node("src","synt",src),"assoc")
        return n

    def match(self,doc):
        try:
            art = self.dict[doc[0].lemma_.lower()]
        except KeyError:
            return (0,None)
        score = 0; entry = None
        for a in art:
            ns = self.calc_score(doc, a["tokens"])
            if ns>score:
                entry = a
                score = ns
        return (len(entry["tokens"]),entry["ids"]) if entry else (0,None)
    def calc_score(self, doc, ent):
        if len(doc)<len(ent):
            return 0
        return func.reduce(op.add, map(lambda x,y: (-3 if not (x["ws"] is None or (len(y.whitespace_)>0) is x["ws"]) else 0) +
            1 if x["word"] == y.text else 0.95 if x["lword"] == y.text.lower() else 0.9 if x["lemma"] == y.lemma_.lower() else -10,ent,doc))

def load_emails(path, encoding='latin1'):
    global EMAILS
    EMAILS = []
    efield = re.compile("^(Date|From|To|Subject|CC): (.*)")
    with codecs.open(path, encoding=encoding) as f:
        for email in ftfy.fix_text(f.read()).split("<MAIL-DELIM>"):
            lines = email.split("\n")
            em = {}
            for (j,l) in enumerate(lines):
                if ESTR.match(l):
                    continue
                fi = efield.match(l)
                if fi:
                    em[fi.groups()[0]] = fi.groups()[1]
                    continue
                em["body"] = lines[j:]
                EMAILS.append(em)
                break

def process_email(e):
    r = {}
    for l in e['body']:
        doc = fnlpTok(l)
        i = 0
        while i<len(doc):
            j,res = DICT.match(doc[i:])
            if res:
                key = res[0].lnext('pointer').key
                val = doc[i:i+j].text
                i += j
            else:
                i,res = ruleSet.match(doc,i)
                if not res:
                    i += 1
                    continue
                if res[2] in ['FXRIC','STOCKRIC','FUTURERIC','SPREADRIC','ISIN','QZNS']:
                    res = DICT.get_repr(res[0],res[1],res[2])
                    key = res.next('matches').value[0].lnext('pointer').key
                    val = res.key
                else:
                    key = res[2]
                    val = res[0]
            if key in r:
                rk = r[key]
                if not val in rk:
                    rk.append(val)
            else:
                r[key] = [val]
    return r

# load_kb("c:/github/fnlp/rules.txt")
# DICT = Dict("c:/github/fnlp/dict.txt")
# exec(open("c:/github/fnlp/node.py").read())
