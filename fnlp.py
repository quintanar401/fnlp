# -*- coding: utf-8 -*-
"""
Created on Mon Jul  9 22:17:59 2018

@author: Andrew
"""


import spacy
from spacy import displacy
from spacy.tokenizer import Tokenizer
import re

txt = u"Symlinks were originally introduced to maintain backwards compatibility, as older versions expected model data to live within spacy/data. However, we decided to keep using them in v2.0 instead of opting for a config file. There'll always be a need for assigning and saving custom model names or IDs. And your system already comes with a native solution to mapping unicode aliases to file paths: symbolic links."

txt = u"I sent email to mary@zzz.ac and then opened the page http://some.zzz.es"

nlp = spacy.load('en_core_web_md')

tokenizer = Tokenizer(nlp.vocab)

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


class TextProxy:
    def __init__(self,txt):
        self.origTxt = txt
        self.text = None
        self.doc = None
        self.process()
    def process(self):
        self.doc = tokenizer(self.origTxt)
        self.txt = ' '.join([self.processToken(i).text for i,_ in enumerate(doc)])
    def processToken(self,i):
        r = ruleSet.match(doc,i)
        return r if r else doc[i]
    def __repr__(self):
        return self.text
        

class Rule:
    def __init__(self,name,regexp,subst):
        self.name = name
        self.subst = subst
        self.regexp = re.compile(regexp)
    def match(self,doc,i):
        r = self.regexp.match(doc[i].text)
        return RuleResult(doc,i,self.subst) if r else None
    
class OrRule:
    def __init__(self, *rules):
        self.rules = rules
    def match(self,doc,i):
        for r in self.rules:
            res = r.match(doc,i)
            if res: return res
        return None

class RuleResult:
    def __init__(self,doc,pos,subst):
        self.pos = pos
        self.doc = doc
        self.text = subst
    def __str__(self):
        return self.subst
    def __repr__(self):
        return self.subst + "[" + self.doc[self.pos].text + "]"

ruleSet = OrRule(
  Rule("email1","([\\w\\._+-]+@[\\w_-]+(\\.[\\w_-]+)+)","email"),
  Rule("email2","([\\w_+-]+(?:(?: dot |\\.)[\\w_+-]+){0,10})(?: at |@)([a-zA-Z]+(?:(?:\\.| dot )[\\w_-]+){1,10})","email"),
  Rule("URL","((([a-zA-Z]+)://)?(w{2,3}[0-9]*\\.)?(([\\w_-]+\\.)+[a-z]{2,4})(:(\\d+))?(/[^?\\s#]*)?(\\?[^\\s#]+)?(#[\\-,*=&a-z0-9]+)?)","page"),
  Rule("Localhost URL","((([a-zA-Z]+)://)?localhost(:(\\d+))?(/[^?\\s#]*)?(\\?[^\\s#]+)?)","page"),
  Rule("Local URL","(([a-zA-Z]+)://([\\w_-]+)(:(\\d+))?(/[^?\\s#]*)?(\\?[^\\s#]+)?)","page"))

ruleSet.match(doc,10)

TextProxy(txt)