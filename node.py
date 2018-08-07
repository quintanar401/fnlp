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
KB = {}
def get_kb_node(name,type="kb",value=None,not_exists=False):
    try:
        nm = KB[name]
        if not_exists:
            raise DuplicateKBRef(name)
        return nm
    except KeyError:
        KB[name] = Node(name,type,value)
        return KB[name]

def load_kb(path):
    global KB
    KB = {}
    with open(path,"rt") as f:
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

DICT = {}
def get_dict_entry(name):
    name = name.lower()
    try:
        return DICT[name]
    except KeyError:
        DICT[name] = {}
        return DICT[name]

def add_dict_entry(name,kb_id):
    W = get_dict_entry(name)
    if not name in W:
        W[name] = [Node(name,"word_proxy").add_node(get_kb_node(kb_id),"pointer")]
        if name.isalpha() and (name in nlp.vocab or name.lower() in nlp.vocab):
            W[name].append(Node(name,"word_proxy").add_node(Node(name,"word"),"pointer"))
    else:
        if not functools.reduce(lambda x,y: x or y.next(kb_id) is not None,W[name],False):
            W[name].append(Node(name,"word_proxy").add_node(get_kb_node(kb_id),"pointer"))
    return W[name]

def load_dict(path):
    with open(path,"rt") as f:
        for str in f:
            if ESTR.match(str):
                continue
            tok = fnlpTok(str)
            w = tok[0].text
            r = range(1,len(tok)) if len(tok)>2 else range(0,1)
            W = get_dict_entry(w)
            nodes = [Node(tok[i].text,"word_proxy").add_node(get_kb_node(tok[i].text),"pointer") for i in r]
            if w.isalpha() and (w in nlp.vocab or w.lower() in nlp.vocab):
                nodes.append(Node(w,"word_proxy").add_node(Node(w,"word"),"pointer"))
            W[w] = nodes

EMAILS = []
def load_emails(path, encoding='latin1'):
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
                    em[fi[1]] = fi[2]
                    continue
                em["body"] = lines[j:]
                EMAILS.append(em)
                break

# load_kb("c:/github/fnlp/rules.txt")
# load_dict("c:/github/fnlp/dict.txt")
