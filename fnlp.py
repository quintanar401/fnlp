# -*- coding: utf-8 -*-
"""
Created on Mon Jul  9 22:17:59 2018

@author: Andrew
"""

from __future__ import print_function
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
INFIX_RULES2 = ["[\[\]\(\)\{\}\!`\:\,;+=<>\\\\/$#\\"]"]
PREFIX_RULES = ["[\./\\\\~]"]
SUFFIX_RULES = ["[\/\\\\\\-|]"]

def extend_tokenizer(nlp,pref,inf,suf):
    pref = tuple(pref + list(nlp.Defaults.prefixes)) if pref else nlp.Defaults.prefixes
    suf = tuple(suf + list(nlp.Defaults.suffixes)) if suf else nlp.Defaults.suffixes
    inf = tuple(inf + list(nlp.Defaults.infixes)) if inf else nlp.Defaults.infixes
    tok = "^(?:"+"|".join([RE[r]["str"] for r in RE['tok_patterns']])+")$"
    return Tokenizer(nlp.vocab,
                       rules = nlp.Defaults.tokenizer_exceptions,
                       prefix_search=spacyUtil.compile_prefix_regex(pref).search,
                       suffix_search=spacyUtil.compile_suffix_regex(suf).search,
                       infix_finditer=spacyUtil.compile_infix_regex(inf).finditer,
                       token_match=re.compile(tok).match)

def process_text(txt):
    doc = fnlpTok(txt)
    i = 0; r = []
    while i<len(doc):
        i,res = ruleSet.match(doc,i)
        r.append(res.next('matches').value[0].lnext('pointer').key)
    return r

def load_re_rules(file, init=False):
    global RE
    if init:
        RE = {}
    with open(file) as f:
        reg = json.load(f)
        for p in reg["patterns"].keys():
            RE[p] = { "type": "re", "name": p, "patterns": [re.compile("^(?:"+reg["patterns"][p]+")$")], "str": reg["patterns"][p]}
        for p in reg["comp_patterns"]:
            # p["patterns"] = [pat for pat in map(lambda x: RE[x], p["patterns"])]
            if "check_fn" in p:
                p["check_fn"] = eval(p["check_fn"])
            else:
                p["check_fn"] = None
            if "convert_fn" in p:
                p["convert_fn"] = eval(p["convert_fn"])
            else:
                p["convert_fn"] = None
            RE[p["name"]]= p
        RE['tok_patterns'] = reg['tok_patterns']
            
def match_re(doc,i,pattern = "main"):
    if i is len(doc):
        return (i,None)
    p = RE[pattern]
    pat = p["patterns"]
    typ = p["type"]
    if typ == "re":
        txt = doc[i].text
        r = pat[0].match(txt)
        if not r:
            return (i,None)
        return (i+1,(txt,doc[i:i+1],p["name"]))
    start = i; r = None
    for pp in pat:
        i,r = match_re(doc,i,pp)
        if not r:
            if typ == "or":
                continue
            else:
                return (start,None)
        if typ == "or":
            break
    if start is i:
        return (start,None)
    if typ == "strict_and":
        for j in range(start,i-1):
            if len(doc[j].whitespace_)>0:
                return (start,None)
    if p["check_fn"] and not p["check_fn"](doc[start:i]):
        return (start,None)
    if typ == "or":
        return (i,r)
    return (i,(p["convert_fn"](doc[start:i]) if p["convert_fn"] else doc[start:i].text,doc[start:i],p["name"]))
        
def check_ccypair(pair):
    return pair[:3] in ccys and pair[3:] in ccys
def check_ccy(ccy):
    return ccy in ccys
def check_year(y):
    return 1800<int(y)<2100
def conv_ccypair(x):
    return x[0].text+x[2].text
def check_int_date(x):
    return len(x) is 8 and 1800<int(x[:4])<2100 and 0<int(x[4:6])<13 and 0<int(x[6:])<32
def check_am_pm(x):
    return 0<int(x[0].text)<13

def get_tokenizer():
    global fnlpTok
    fnlpTok = extend_tokenizer(nlp,PREFIX_RULES,INFIX_RULES2,SUFFIX_RULES)
    for r in get_special_rules():
        fnlpTok.add_special_case(r[0],r[1])
        
get_tokenizer()