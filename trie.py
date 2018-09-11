class Trie:
    def __init__(self):
        self.dict = {}
        self.total_len = 0
        self.len = 0
        self.shifts = [0,2,5,8,12,17,10000]
    def __len__(self):
        return self.total_len
    def __setitem__(self, item, data):
        dict = self.dict; s = self.shifts; i = 0
        while s[i] < len(item):
            c = item[s[i]:s[i+1]]; i += 1
            try:
                dict = dict[c]
            except KeyError:
                dict[c] = {}
                dict = dict[c]
        if "data" in dict:
            dict["data"].append(data)
            self.total_len += 1
        else:
            dict["data"] = [data]
            self.total_len += 1
            self.len += 1
    def __getitem__(self, item):
        dict = self.dict; s = self.shifts; i = 0
        while s[i] < len(item):
            c = item[s[i]:s[i+1]]; i += 1
            try:
                dict = dict[c]
            except KeyError:
                return []
        return dict["data"] if "data" in dict else []
    def __contains__(self, item):
        return len(self[item]) > 0
