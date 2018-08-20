import urllib.request as Request
import re
from urllib.parse import urljoin
from html.parser import HTMLParser

URLS = {}

class webHTMLParser(HTMLParser):
    def __init__(self,base):
        global URLS
        self.data = []
        self.base = base
        self.tags = { "code": 0, "article": 0, "p": 0, "a":0}
        HTMLParser.__init__(self)
        URLS[base] = True
        self.re = re.compile(".*(?i)\\.(pdf|png|jpeg|jpg|q)$")
    def handle_starttag(self, tag, attrs):
        global URLS
        if tag in self.tags:
            self.tags[tag] += 1
        else:
            self.tags[tag] = 1
        if tag == "a":
            href = self.get_attr(attrs,"href")
            if href:
                if not ':' in href and not '#' in href and href == "/":
                    url = urljoin(self.base,href)
                    if not url in URLS and not (url+"/") in URLS:
                        URLS[url] = False
    def handle_endtag(self, tag):
        self.tags[tag] = max(0,self.tags[tag]-1)

    def handle_data(self, data):
        pass
    def get_attr(self, attrs, attr):
        attrs = [a for a in attrs if a[0] == attr]
        if len(attrs)>0:
            return attrs[0][1]
        return None

class kxHTMLParser(webHTMLParser):
    def handle_starttag(self, tag, attrs):
        webHTMLParser.handle_starttag(self, tag, attrs)
        if tag == "a" and (self.tags['code']>0 or self.tags['article']>0):
            href = self.get_attr(attrs,"href")
            if href:
                if href[0] == "#":
                    self.data.append("<<link:{}>>".format(href[1:]))
        if tag == "code":
            cl = self.get_attr(attrs,"class")
            cl  = cl.split(" ")[0] if cl else ""
            self.data.append("<<code start|"+cl+">>")
    def handle_endtag(self, tag):
        webHTMLParser.handle_endtag(self, tag)
        if tag == "code":
            self.data.append("<<code end>>")
    def handle_data(self, data):
        if (self.tags['code']>0 or self.tags['article']>0):
            self.data.append(data)

def get_url(url):
    with Request.urlopen(url) as req:
        p = kxHTMLParser(url)
        p.feed(str(req.read()))
        return p.data
