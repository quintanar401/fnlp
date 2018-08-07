# -*- coding: utf-8 -*-
"""
Created on Mon Jul  9 22:17:59 2018

@author: Andrew
"""


import spacy
from spacy import displacy
from spacy.tokenizer import Tokenizer
from spacy import util as spacyUtil
import re
import json
import ftfy
import codecs
import functools

with open('c:/github/fnlp/ccy.json') as f:
    ccyInfo = json.load(f)
ccys = set(ccy['code'] for ccy in ccyInfo)

txt = u"Symlinks were originally introduced to maintain backwards compatibility, as older versions expected model data to live within spacy/data. However, we decided to keep using them in v2.0 instead of opting for a config file. There'll always be a need for assigning and saving custom model names or IDs. And your system already comes with a native solution to mapping unicode aliases to file paths: symbolic links."

txt = u"I sent email to mary@zzz.ac and then opened the page http://some.zzz.es"

nlp = spacy.load('en_core_web_md')

doc = nlp(txt)

# displacy.serve(doc2, style='dep')

for t in doc.noun_chunks:
    print(t.text)

for t in doc.ents:
    print(t.text + " " + t.label_)
    
for token in doc:
    print(token.text, token.lemma_, token.pos_, token.tag_, token.dep_,
          token.shape_, token.is_alpha, token.is_stop, token.head.text, token.norm_)
    

spacy.explain('punct')


# Default spacy tokenizer doesn't split by ( ) ; and etc in the infix position, and similar things for prefixes
# on the other hand it is useful to extract emails, urls and etc
tokenizer = nlp.tokenizer
INFIX_RULES1 = ["[\[\]\(\)\{\}\!\.\:\,;]"]
INFIX_RULES2 = ["[\[\]\(\)\{\}\!`\:\,;+=<>]"]
PREFIX_RULES = ["[\.]"]
EMAIL = "([\\w\\._+-]+@[\\w_-]+(\\.[\\w_-]+)+)" + "|" +\
        "([\\w_+-]+(?:(?: dot |\\.)[\\w_+-]+){0,10})(?: at |@)([a-zA-Z]+(?:(?:\\.| dot )[\\w_-]+){1,10})"
URL = "((([a-zA-Z]+)://)?(w{2,3}[0-9]*\\.)?(([\\w_-]+\\.)+[a-z]{2,4})(:(\\d+))?(/[^?\\s#]*)?(\\?[^\\s#]+)?(#[\\-,*=&a-z0-9]+)?)" + "|" +\
    "((([a-zA-Z]+)://)?localhost(:(\\d+))?(/[^?\\s#]*)?(\\?[^\\s#]+)?)" + "|" +\
    "(([a-zA-Z]+)://([\\w_-]+)(:(\\d+))?(/[^?\\s#]*)?(\\?[^\\s#]+)?)"
FXRIC = "(?:[A-Z]{6}|[A-Z]{3})=[WR]?"
STOCKRIC = "[A-Z\d][A-Za-z\d]*-?[A-Za-z\d]*_?[A-Za-z\d]*\.(?:[A-Z]{1,3}|xbo|[A-Z]{2}f)"
FUTURERIC = "[A-Z]{2,5}(?:[A-Z]\d|c\d\d?|cv\d|cvoi\d|coi\d)(?:=LX)?"
SPREADRIC = "[A-Z]{2,4}(?:c\d-[A-Z]{2,4}c\d|-[A-Z]{3,5}\d|[A-Z]\d-[A-Z]\d)"
ISIN = "[A-Z]{2}[A-Z\d]{9}\d"
DATE = "[12]\d\d\d[\.-][01]\d[\.-][0-3]\d"
QSPAN = "\d+D\d([\d:\.])+"
QDATETIME = "\d\d\d\d{4}\.[01]\d\.[0-3]\dD\d([\d:\.])+"
ARROWS = "-+>+|<+-+|<+-+>+"
UNKNOWN = "[A-Z]\w*[A-Z\d]\w*|\d\w*[A-Z]\w*"
    

def extend_tokenizer(nlp,pref,inf,suf):
    pref = tuple(pref + list(nlp.Defaults.prefixes)) if pref else nlp.Defaults.prefixes
    suf = tuple(suf + list(nlp.Defaults.suffixes)) if suf else nlp.Defaults.suffixes
    inf = tuple(inf + list(nlp.Defaults.infixes)) if inf else nlp.Defaults.infixes
    tok = "^(?:"+"|".join([EMAIL,URL,FXRIC,STOCKRIC,SPREADRIC,DATE,QSPAN,QDATETIME,ARROWS])+")$"
    return Tokenizer(nlp.vocab,
                       rules = nlp.Defaults.tokenizer_exceptions,
                       prefix_search=spacyUtil.compile_prefix_regex(pref).search,
                       suffix_search=spacyUtil.compile_suffix_regex(suf).search,
                       infix_finditer=spacyUtil.compile_infix_regex(inf).finditer,
                       token_match=re.compile(tok).match)

fnlpTok = extend_tokenizer(nlp,PREFIX_RULES,INFIX_RULES2,None)


def process_text(txt):
    doc = fnlpTok(txt)
    i = 0; r = []
    while i<len(doc):
        i,res = ruleSet.match(doc,i)
        if not res:
            res = add_dict_entry(doc[i].text,'ENTITY')
            i+=1
        r.append(res)
    return r
        

class Rule:
    def __init__(self,kb_id,regexp):
        self.kb_id = kb_id
        self.regexp = re.compile("^(?:"+regexp+")$")
    def match(self,doc,i):
        if i is len(doc):
            return (i,None)
        txt = doc[i].text
        r = self.regexp.match(txt)
        if not r:
            return (i,None)
        n = Node(txt,"word_repr").add_node(Node("matches","synt",add_dict_entry(txt,self.kb_id)),"assoc")
        n.add_node(Node("src","synt",(doc,i,i)),"assoc")
        return (i+1,n)
    
class CondRule(Rule):
    def __init__(self,name,regexp,checkFn):
        self.checkFn = checkFn
        super().__init__(name,regexp)
    def match(self,doc,i):
        j,res = super().match(doc,i)
        if res and self.checkFn(res.key):
            return (j,res)
        return (i,None)
    
class OrRule:
    def __init__(self, *rules):
        self.rules = rules
    def match(self,doc,i):
        for r in self.rules:
            j,res = r.match(doc,i)
            if res: return (j,res)
        return (i,None)

class StrictAndRule:
    def __init__(self, kb_id, *rules):
        self.rules = rules
        self.kb_id = kb_id
    def match(self,doc,i):
        start = i
        for r in self.rules:
            i, res = r.match(doc,i)
            if not res:
                return (start,None)
        for j in range(start,i-1):
            if len(doc[j].whitespace_)>0:
                return (start,None)
        return (i,res)
                

def check_ccypair(pair):
    return pair[:3] in ccys and pair[3:] in ccys

ruleSet = OrRule(
  Rule("email",EMAIL),
  Rule("URL",URL),
  Rule("fx_ric",FXRIC),
  Rule("stock_ric",STOCKRIC),
  Rule("future_ric",FUTURERIC),
  Rule("spread_ric",SPREADRIC),
  Rule("ISIN",ISIN),
  Rule("date",DATE),
  Rule("q_span",QSPAN),
  Rule("q_datetime",QDATETIME),
  Rule("ARROW",ARROWS),
  CondRule("ccy_pair","[A-Z]{6}",check_ccypair),
  CondRule("ccy","[A-Z]{3}",lambda x: x in ccys),
  Rule("symbol",UNKNOWN),
  Rule("ENTITY",".*"))
