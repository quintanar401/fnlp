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
            if ESTR.match(str):
                continue
            tok = fnlpTok(str)
            if tok[0].text == "#":
                t1, rel, t2, ex = (tok[1].text, tok[2].text, tok[3].text, False)
            else:
                t1, rel, t2, ex = (tok[0].text, tok[1].text, tok[2].text, True)
            print(tok)
            if rel == "is":
                Link(get_kb_node(t1, not_exists=ex),"kb",get_kb_node(t2))
            else:
                raise UnknownLinkType(rel)

class Dict:
    def __init__(self, path, encoding='latin1'):
        self.dict = {}
        with codecs.open(path, encoding=encoding) as f:
            for str in f:
                if ESTR.match(str):
                    continue
                tok = fnlpTok(str)
                w = tok[0].text
                r = range(1,len(tok)) if len(tok)>2 else range(0,1)
                W = self.get_entry(w)
                nodes = [Node(tok[i].text,"word_proxy").add_node(get_kb_node(tok[i].text),"pointer") for i in r]
                if w.isalpha() and (w in nlp.vocab or w.lower() in nlp.vocab):
                    nodes.append(Node(w,"word_proxy").add_node(Node(w,"word"),"pointer"))
                W[w] = nodes

    def __contains__(self, val):
        return val in self.dict

    def __getitem__(self, name):
        return self.dict[name.lower()]

    def get_entry(self, name):
        name = name.lower()
        try:
            return self.dict[name]
        except KeyError:
            self.dict[name] = {}
            return self.dict[name]

    def add_entry(self, name, kb_id):
        W = self.get_entry(name)
        if not name in W:
            W[name] = [Node(name,"word_proxy").add_node(get_kb_node(kb_id),"pointer")]
            if name.isalpha() and (name in nlp.vocab or name.lower() in nlp.vocab):
                W[name].append(Node(name,"word_proxy").add_node(Node(name,"word"),"pointer"))
        else:
            if not functools.reduce(lambda x,y: x or y.next(kb_id) is not None,W[name],False):
                W[name].append(Node(name,"word_proxy").add_node(get_kb_node(kb_id),"pointer"))
        return W[name]

    def get_repr(self, txt, src, kb_id):
        n = Node(txt,"word_repr").add_node(Node("matches","synt",self.add_entry(txt,kb_id)),"assoc")
        n.add_node(Node("src","synt",src),"assoc")
        return n

    def match(self,entry):
        try:
            art = self.dict[entry.text.lower()]
        except KeyError:
            try:
                art = self.dict[entry.lemma_.lower()]
            except KeyError:
                return None
        return functools.reduce(lambda x,y: x or (art[y] if y in art else None),[entry.text,entry.lemma_,entry.text.lower(),entry.lemma_.lower()],None)

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
    for l in e:
        doc = fnlpTok(l)
        i = 0
        while i<len(doc):
            res = DICT.match(doc[i])
            if res:
                key = res[0].lnext('pointer').key
                val = doc[i].text
                i += 1
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
