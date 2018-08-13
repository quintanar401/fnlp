# -*- coding: utf-8 -*-
"""
Created on Mon Jul  9 22:17:59 2018

@author: Andrew
"""


import spacy
from spacy import displacy
from spacy.tokenizer import Tokenizer
from spacy import util as spacyUtil
from spacy.symbols import ORTH, LEMMA
import re
import json
import ftfy
import codecs
import functools as func
import itertools as itr
import operator as op

with open('c:/github/fnlp/ccy.json') as f:
    ccyInfo = json.load(f)
ccys = set(ccy['code'] for ccy in ccyInfo)

nlp = spacy.load('en_core_web_md')

# displacy.serve(doc2, style='dep')

#for t in doc.noun_chunks:
#    print(t.text)

#for t in doc.ents:
#    print(t.text + " " + t.label_)
    
#for token in doc:
#    print(token.text, token.lemma_, token.pos_, token.tag_, token.dep_,
#          token.shape_, token.is_alpha, token.is_stop, token.head.text, token.norm_)
    

#spacy.explain('punct')


# Default spacy tokenizer doesn't split by ( ) ; and etc in the infix position, and similar things for prefixes
# on the other hand it is useful to extract emails, urls and etc
tokenizer = nlp.tokenizer
INFIX_RULES1 = ["[\[\]\(\)\{\}\!\.\:\,;]"]
INFIX_RULES2 = ["[\[\]\(\)\{\}\!`\:\,;+=<>\\\\/]"]
PREFIX_RULES = ["[\./\\\\]"]
SUFFIX_RULES = ["[\/\\\\]"]
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
QDATETIME = "\d{4}\.[01]\d\.[0-3]\dD\d([\d:\.])+"
QTIME = "\d\d:\d\d(?::\d\d(?:\.\d+)?)?"
DATE_dWd = "(?i)\d\d-(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)-\d\d"
QZNS = "\.z\.(?:[abcefhikKlnNopPqsuwWxXzZtTdD]|p[cdghimopsw]|w[cos]|zd|exit|ac|bm)"
ARROWS = "-+>+|<+-+|<+-+>+"
UNKNOWN = "[A-Z]\w*[A-Z\d]\w*|\d\w*[A-Z]\w*|[a-z]\w*[A-Z\d]\w*"
    

def extend_tokenizer(nlp,pref,inf,suf):
    pref = tuple(pref + list(nlp.Defaults.prefixes)) if pref else nlp.Defaults.prefixes
    suf = tuple(suf + list(nlp.Defaults.suffixes)) if suf else nlp.Defaults.suffixes
    inf = tuple(inf + list(nlp.Defaults.infixes)) if inf else nlp.Defaults.infixes
    tok = "^(?:"+"|".join([EMAIL,URL,FXRIC,STOCKRIC,SPREADRIC,DATE,QSPAN,QDATETIME,QTIME,QZNS,ARROWS])+")$"
    return Tokenizer(nlp.vocab,
                       rules = nlp.Defaults.tokenizer_exceptions,
                       prefix_search=spacyUtil.compile_prefix_regex(pref).search,
                       suffix_search=spacyUtil.compile_suffix_regex(suf).search,
                       infix_finditer=spacyUtil.compile_infix_regex(inf).finditer,
                       token_match=re.compile(tok).match)

fnlpTok = extend_tokenizer(nlp,PREFIX_RULES,INFIX_RULES2,SUFFIX_RULES)
for r in special_rules:
    fnlpTok.add_special_case(r[0],r[1])


def process_text(txt):
    doc = fnlpTok(txt)
    i = 0; r = []
    while i<len(doc):
        i,res = ruleSet.match(doc,i)
        r.append(res.next('matches').value[0].lnext('pointer').key)
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
        return (i+1,(txt,doc[i:i+1],self.kb_id))
    
class CondRule(Rule):
    def __init__(self,name,regexp,checkFn):
        self.checkFn = checkFn
        Rule.__init__(self,name,regexp)
    def match(self,doc,i):
        j,r = Rule.match(self,doc,i)
        if r and self.checkFn(r[0]):
            return (j,r)
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
        return (i,(doc[start:i].text,doc[start:i],self.kb_id))

class AndRule:
    def __init__(self, kb_id, conv_fn, *rules):
        self.rules = rules
        self.kb_id = kb_id
        self.fn = conv_fn
    def match(self,doc,i):
        start = i
        for r in self.rules:
            i, res = r.match(doc,i)
            if not res:
                return (start,None)
        return (i,(self.fn(doc[start:i]),doc[start:i],self.kb_id))                

def check_ccypair(pair):
    return pair[:3] in ccys and pair[3:] in ccys

ccyRule = CondRule("ccy","[A-Z]{3}",lambda x: x in ccys)
ruleSet = OrRule(
  AndRule("ccy",lambda x: x[0].text+x[2].text,ccyRule,Rule("","/"),ccyRule),
  StrictAndRule("index_ric",Rule("","\."),Rule("",UNKNOWN)),
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
  Rule("q_time",QTIME),
  Rule("date_dWd",DATE_dWd),
  Rule("q_dot_z",QZNS),
  Rule("ARROW",ARROWS),
  CondRule("ccy_pair","[A-Z]{6}",check_ccypair),
  ccyRule,
  Rule("symbol",UNKNOWN))
