from __future__ import print_function
from bisect import bisect_left
from spacy.strings import hash_string

def list_index(a, x):
    'Locate the leftmost value exactly equal to x'
    i = bisect_left(a, x)
    if i != len(a) and a[i] == x:
        return i
    raise ValueError

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
    def lnext(self,key,nkey=None):
        if type(key) is str:
            key = [key]
        for l in self.links_to:
            if l.type in key:
                if nkey and not l.to.key == nkey:
                    continue
                return l.to
        return None
    def add_node(self,node,ltype,lSubType=None):
        Link(self,ltype,node,subType=lSubType)
        return self
    def isA(self,key,lkeys=["is"]):
        if key == self.key:
            return True
        for l in self.links_to:
            if l.type in lkeys:
                if l.to.isA(key):
                    return True
        return False

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
            if rel in ["is","isA"]:
                Link(get_kb_node(t1, not_exists=ex),rel,get_kb_node(t2))
            else:
                raise UnknownLinkType(rel)

class Dict:
    def __init__(self, path, encoding='latin1'):
        self.dict = { "#re": []}
        self.index = []
        self.array = []
        self.add_dict(path, encoding)
    def add_dict(self, path, encoding='latin1'):
        with codecs.open(path, encoding=encoding) as f:
            for str in f:
                if ESTR2.match(str):
                    continue
                self.add_dict_entry(str.strip("\r\n"))
            self.hash_entries()
    def add_dict_entry(self,str):
        'Add one dictionary entry.'
        toks = []; brk = None; esc = False; i = 0; doc = fnlpTok(str); nolemma = False; re_rule = False; opts = {}
        while i < len(doc):
            t = doc[i]
            i += 1
            if esc:
                esc = False
            elif t.text == "\\":
                esc = True
                continue
            elif t.text == "!":
                nolemma = True
                continue
            elif t.text == "$":
                re_rule = True
                continue
            elif t.text == "{":
                while doc[i].text != "}":
                    if doc[i+1].text == "=":
                        opts[doc[i].text] = eval(doc[i+2].text) if doc[i].text[-3:] == "_fn" else doc[i+2].text
                        i += 3
                    else:
                        opts[doc[i].text] = True
                        i += 1
                i += 1
                continue
            elif t.text in ["'",'"']:
                if brk:
                    break
                brk = t.text
                continue
            ntok = { "word": t.text, "lword": t.text.lower(), "lemma": "**nolemma**" if nolemma else fnlpTok(t.text.lower())[0].lemma_, "ws": not brk == "'" and len(t.whitespace_)>0,
                "re": re_rule, "opts": opts }
            re_rule = nolemma = False; opts = {}
            toks.append(ntok)
            if (not brk) and ntok["ws"]:
                break
        toks[-1]["ws"] = None
        kbw = [toks[-1]["word"]] if i is len(doc) else [t.text for t in doc[i:]]
        W = self.get_entry("#re" if toks[0]["re"] else toks[0]["lword"])
        entry = self.match_exact_entry_tokens(W,toks) if len(W) and not toks[0]["re"] else None
        if entry:
            kbw = [f for f in filter(lambda x: not any(map(lambda y: y.next(x),entry["ids"])),kbw)]
            entry["ids"] += [Node(t,"word_proxy").add_node(get_kb_node(t),"pointer") for t in kbw]
            return entry["ids"]
        W.append({ "tokens": toks, "ids": [Node(t,"word_proxy").add_node(get_kb_node(t),"pointer") for t in kbw]})
        return W[-1]["ids"]
    def match_exact_entry_tokens(self, entry, tokens):
        'Check if entry already exists.'
        for e in entry:
            ent = e["tokens"]
            if not len(ent) is len(tokens):
                continue
            if func.reduce(lambda x,y: x and (ent[y]["word"] == tokens[y]["word"] and ent[y]["ws"] is tokens[y]["ws"]), range(len(tokens)), True):
                return e
        return None

    def __contains__(self, val):
        return 0<len(self.get_entry(name))

    def __getitem__(self, name):
        return self.get_entry(name)

    def get_entry(self, name):
        'Get dictionary entry. Returns entries mapped to name\'s lemma. If the word doesn\'t exists returns an empty list.'
        name = name if name[0] == "#" else self.get_lemma(name)
        hash = hash_string(name)
        try:
            return self.array[list_index(self.index,hash)]
        except ValueError:
            try:
                return self.dict[hash]
            except KeyError:
                self.dict[hash] = []
                return self.dict[hash]
    def hash_entries(self):
        'Move dict entries from a dictionary to an array indexed by hash.'
        if len(self.dict) is 0:
            return
        self.index += list(self.dict.keys())
        self.array += list(self.dict.values())
        self.dict = {}
        iasc = list(range(len(self.index)))
        iasc.sort(key=lambda x: self.index[x])
        self.index = [self.index[i] for i in iasc]
        self.array = [self.array[i] for i in iasc]

    def get_repr(self, txt, src, kb_id):
        n = Node(txt,"word_repr").add_node(Node("matches","synt",self.add_dict_entry(txt+" "+kb_id)),"assoc")
        n.add_node(Node("src","synt",src),"assoc")
        return n

    def match(self,doc):
        'Match the start of doc (tokenized by fnlpTok) vs dictionary. Returns either (0,None) or (shift,entries)'
        art = self.dict['#re']
        try:
            art += self.get_entry(doc[0].text)
        except KeyError:
            pass
        score = 0; entry = None
        for a in art:
            ns = self.calc_score(doc, a["tokens"])
            if ns>score:
                entry = a
                score = ns
        return (len(entry["tokens"]),entry["ids"]) if entry else (0,None)
    def calc_score(self, doc, ent):
        'Calculate the match score for 1 entry.'
        if len(doc)<len(ent):
            return 0
        return func.reduce(op.add, map(self._score,ent,doc[0:len(ent)]))
    def _score(self,x,y):
        ws_score = 0 if not x["ws"] is False or (len(y.whitespace_)>0) is x["ws"] else -3
        if x['re']:
            p = RE[x['word']]['patterns'][0].match
            word_score = 1 if p(y.text) else -100
            if p(y.text):
                word_score = -100 if "check_fn" in x['opts'] and not x['opts']["check_fn"](y.text) else 1
            else:
                word_score = -100
        else:
            lemma = fnlpTok(y.text.lower())[0].lemma_
            word_score = 1 if x["word"] == y.text else 0.95 if x["lword"] in [y.text.lower(),lemma] else 0.9 if x["lemma"] == lemma else -10
        return word_score + ws_score

    def get_lemma(self, word):
        'Calculate lemma recursively until it stops to change to ensure stability.'
        l = fnlpTok(word.lower())[0].lemma_
        while not l == word:
            word = l
            l = fnlpTok(l)[0].lemma_
        return l

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
                i,res = match_re(doc,i)
                if not res:
                    print(doc[i].text+doc[i].whitespace_, end="")
                    i += 1
                    continue
                if res[2] in ['FXRIC','STOCKRIC','FUTURERIC','SPREADRIC','ISIN','QZNS']:
                    res = DICT.get_repr(res[0],res[1],res[2])
                    key = res.next('matches').value[0].lnext('pointer').key
                    val = res.key
                else:
                    key = res[2]
                    val = res[0]
            print(val+"<"+key+">"+doc[i-1].whitespace_, end="")
            if key in r:
                rk = r[key]
                if not val in rk:
                    rk.append(val)
            else:
                r[key] = [val]
        print("")
    return r

# load_kb("c:/github/fnlp/rules.txt")
# DICT = Dict("c:/github/fnlp/dict.txt")
# exec(open("c:/github/fnlp/node.py").read())
