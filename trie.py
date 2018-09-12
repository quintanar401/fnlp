class Trie:
    def __init__(self):
        self.dict = {}
        self.total_len = 0
        self.len = 0
        self.shifts = [0,2,5,8,12,17,10000]
    def __len__(self):
        return self.total_len
    def __setitem__(self, item, data):
        dict = self.dict; s = self.shifts; i = 1
        while s[i] < len(item):
            c = item[s[i-1]:s[i]]; i += 1
            try:
                d = dict[c]
                if type(d) is list:
                    dict[c] = { "data": d}
                    d = dict[c]
                dict = d
            except KeyError:
                dict[c] = {}
                dict = dict[c]
        c = item[s[i-1]:s[i]]
        try:
            dict = dict[c]
            if type(dict) is list:
                dict.append(data)
                self.len += 1
            elif "data" in dict:
                dict["data"].append(data)
                self.len += 1
            else:
                dict["data"] = [data]
        except KeyError:
            dict[c] = [data]
        self.total_len += 1
    def __getitem__(self, item):
        dict = self.dict; s = self.shifts; i = 0
        while s[i] < len(item):
            if type(dict) is list:
                return []
            c = item[s[i]:s[i+1]]; i += 1
            try:
                dict = dict[c]
            except KeyError:
                return []
        return dict if type(dict) is list else dict["data"] if "data" in dict else []
    def __contains__(self, item):
        return len(self[item]) > 0
