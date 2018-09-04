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
    def lnext(self,key,nkey=None,last=False):
        if type(key) is str:
            key = [key]
        for l in reversed(self.links_to) if last else self.links_to:
            if l.type in key:
                if nkey and not l.to.key == nkey:
                    continue
                return l.to
        return None
    def add_node(self,node,ltype,lSubType=None, ret_arg = False):
        Link(self,ltype,node,subType=lSubType)
        return node if ret_arg else self
    def isA(self,key,lkeys=["is","isA"]):
        if self.type == "kb_ref":
            if self.value and get_kb_node(self.value).isA(key, lkeys):
                return True
        if len(lkeys) is 1:
            if lkeys[0] == "isA":
                return self._isAExact(key,True)
            elif lkeys[0]== "has":
                return self._has(key)
        return self._isA(key,lkeys)
    def _isAExact(self, key, follow_isA = True):
        if not follow_isA and key == self.key:
            return True
        for l in self.links_to:
            if l.type == "isA" and follow_isA and l.to._isAExact(key, False):
                return True
            elif l.type == "is" and l.to._isAExact(key, follow_isA):
                return True
        return False
    def _isA(self,key,lkeys):
        if key == self.key:
            return True
        for l in self.links_to:
            if l.type in lkeys:
                if l.to.isA(key, lkeys):
                    return True
        return False
    def _has(self, key, exact = False):
        for l in self.links_to:
            if l.type in ["is","isA"] and l.to._has(key, exact):
                return True
            elif l.type == "has" and l.to.isA(key):
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
    pass
class UnknownLinkType(BaseFNLPException):
    pass
class DuplicateKBRef(BaseFNLPException):
    pass
class WrongL2DictFormat(BaseFNLPException):
    pass

ESTR = re.compile("^\s*$")
ESTR2 = re.compile("^(\s*|\s*#.*)\r?\n?$")
ECMT = re.compile("(.*) # .*$")

def get_kb_node(name,type="kb",value=None,not_exists=False):
    try:
        nm = KB[name]
        if not_exists:
            raise DuplicateKBRef(name)
        return nm
    except KeyError:
        KB[name] = Node(name,type,value)
        return KB[name]

def load_kb(path, encoding='latin1', init=True):
    global KB
    if init:
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
            if rel in ["is","isA","in"]:
                Link(get_kb_node(t1, not_exists=ex),rel,get_kb_node(t2))
            else:
                raise UnknownLinkType(rel)

class Dict:
    def __init__(self, path, encoding='latin1'):
        self.dict = { hash_string(u"#re"): [], hash_string(u"#lvl2"): []}
        self.index = []
        self.array = []
        self.add_dict(path, encoding)
    def add_dict(self, path, encoding='latin1'):
        self._add_dict(path, encoding, self.add_dict_entry)
    def add_l2dict(self, path, encoding='latin1'):
        self._add_dict(path, encoding, self.add_l2dict_entry)
    def _add_dict(self, path, encoding, func):
        with codecs.open(path, encoding=encoding) as f:
            for str in f:
                r = ECMT.match(str)
                str = r.group(1) if r else str
                if ESTR2.match(str):
                    continue
                func(str.strip("\r\n "))
            self.hash_entries()
    def add_l2dict_entry(self,str):
        i = 0; doc = fnlpTok(str);
        i, defs = self.parse_defs(i,doc)
        _, rls = self.parse_defs(i,doc,rules=True)
        self.get_entry(u"#lvl2").append({ "defs": defs, "rules": rls})
    def parse_defs(self, i, doc, rules=False):
        i, df = self.parse_def(i, doc)
        defs = [df] if rules else [[df]]
        while len(doc) > i and doc[i-1].text == ",":
            i, df = self.parse_def(i, doc)
            if rules:
                defs.append(df)
                continue
            for d in defs:
                if (df["var"] == d[0]["var"]):
                    d.append(df)
            else:
                defs.append([df])
        return i, defs
    def parse_def(self, i, doc):
        'assume x is something / something is x /  x / somethin for now'
        if len(doc) is i+1 or doc[i+1].text in [":",","]:
            df = { "v1": self.is_var(doc[i].text), "links": [], "node1": doc[i].text, "node2": None, "v2": False}
            df["var"] = df["node1"] if df["v1"] else None
            df["node"] = None if df["v1"] else df["node1"]
            return i+2, df
        df = { "node1": doc[i].text, "links": doc[i+1].text.split("."), "v1": self.is_var(doc[i].text), "v2": self.is_var(doc[i+2].text), "node2": doc[i+2].text}
        df["var"] = df["node1"] if df["v1"] else df["node2"] if df["v2"] else None
        df["node"] = df["node1"] if not df["v1"] else df["node2"] if not df["v2"] else None
        if not (len(doc) is i+3 or doc[i+3].text in [":",","]):
            raise WrongL2DictFormat(doc.text)
        return i+4, df
    def is_var(self, x):
        return len(x) is 1 or x[1:].isdigit()
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
                        txt = doc[i+2].text
                        opts[doc[i].text] = eval(txt) if doc[i].text[-3:] == "_fn" else float(txt) if RE["FLOAT"]["re"].match(txt) else txt
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
        W = self.get_entry(u"#re" if toks[0]["re"]  else toks[0]["lword"])
        entry = self.match_exact_entry_tokens(W,toks) if len(W) and not toks[0]["re"] else None
        if entry:
            kbw = [f for f in filter(lambda x: x in entry["ids"],kbw)]
            entry["ids"] += kbw
            return entry["ids"]
        W.append({ "tokens": toks, "ids": kbw})
        return W[-1]["ids"]
    def match_exact_entry_tokens(self, entry, tokens):
        'Check if entry already exists.'
        for e in entry:
            ent = e["tokens"]
            if not len(ent) is len(tokens):
                continue
            if func.reduce(lambda x,y: x and (ent[y]["word"] == tokens[y]["word"] and ent[y]["lemma"] == tokens[y]["lemma"] and ent[y]["ws"] is tokens[y]["ws"]), range(len(tokens)), True):
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

    def get_repr(self, txt, kb_id):
        n = Node(txt, "kb_ref", kb_id)
        return n

    def match_sentence(self,doc):
        start = Node("sentence_head","synt",doc); curr = start; i = 0
        while i<len(doc):
            j,res = self.match(doc[i:])
            if res:
                repr = { "tokens": doc[i:i+j], "kb_ids": [self.get_repr(t, t) for t in res], "ws": False }
            else:
                j,res = match_re(doc,i)
                if res:
                    repr = { "tokens": res[1], "kb_ids": [self.get_repr(res[2], res[2])], "ws": False }
                else:
                    repr = { "tokens": doc[i:i+1], "kb_ids": [], "ws": False }
            repr["ws"] = len(repr["tokens"][-1].whitespace_)>0
            curr = curr.add_node(Node("sentence_token","synt",repr), "next", ret_arg=True)
            i += len(repr["tokens"])
        lvl2 = DICT[u"#lvl2"]
        while True:
            curr = start.lnext("next", last=True); prev = start; no_change = True
            while curr:
                for r in lvl2:
                    curr2 = prev; succ = True; env = {}
                    for t in r["defs"]:
                        curr2 = curr2.lnext("next", last=True)
                        if not curr2 or not check_kb(t, curr2.value["kb_ids"], env) :
                            succ = False
                            break
                    if succ:
                        curr = prev.add_node(Node("sentence_token","synt",{ "tokens": start.value[curr.value["tokens"][0].i:1+curr2.value["tokens"][-1].i],
                            "kb_ids": apply_rules(r["rules"], env) }), "next", ret_arg=True)
                        nxt = curr2.lnext("next", last=True)
                        if nxt:
                            curr.add_node(nxt, "next")
                        no_change = False
                        break
                prev = curr
                curr = curr.lnext("next", last=True)
            if no_change:
                break
        return start

    def match(self,doc):
        'Match the start of doc (tokenized by fnlpTok) vs dictionary. Returns either (0,None) or (shift,entries)'
        art = self.get_entry(u'#re')
        try:
            art = art + self.get_entry(doc[0].text)
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
            p = RE[x['word']]['patterns'][0].match(y.text)
            p = len(y.text) is p.end() if p else False
            if p:
                word_score = -100 if "check_fn" in x['opts'] and not x['opts']["check_fn"](y.text) else 0.99
            else:
                word_score = -100
        else:
            lemma = fnlpTok(y.text.lower())[0].lemma_
            word_score = 1 if x["word"] == y.text else 0.95 if x["lword"] in [y.text.lower(),lemma] else 0.9 if x["lemma"] == lemma else -10
        return ws_score + word_score * (x["opts"]["score"] if "score" in x["opts"] else 1)

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
        process_sent(l,r)
    return r

def process_sent(l,r={}):
    curr = DICT.match_sentence(fnlpTok(l)).lnext("next", last=True)
    while curr:
        repr = curr.value
        if len(repr["kb_ids"]):
            key = repr["kb_ids"][0].key; val = repr["tokens"].text
            print(val+"<"+key+str(len(repr["tokens"]))+">"+repr["tokens"][-1].whitespace_, end="")
            if key in r:
                rk = r[key]
                if not val in rk:
                    rk.append(val)
            else:
                r[key] = [val]
        else:
            print(repr["tokens"].text_with_ws, end="")
        curr = curr.lnext("next", last=True)
    print("")
    return r

def process_sent(l,r={}):
    curr = DICT.match_sentence(fnlpTok(l)).lnext("next", last=True)
    while curr:
        repr = curr.value
        if len(repr["kb_ids"]):
            key = repr["kb_ids"][0].key; val = repr["tokens"].text
            desc = ",".join([ln.type+":"+ln.to.key for ln in repr["kb_ids"][0].links_to])
            print(val+"<"+key+str(len(repr["tokens"]))+desc+">"+repr["tokens"][-1].whitespace_, end="")
            if key in r:
                rk = r[key]
                if not val in rk:
                    rk.append(val)
            else:
                r[key] = [val]
        else:
            print(repr["tokens"].text_with_ws, end="")
        curr = curr.lnext("next", last=True)
    print("")
    return r


# load_kb("c:/github/fnlp/rules.txt")
# DICT = Dict("c:/github/fnlp/dict.txt")
# exec(open("c:/github/fnlp/node.py").read())
