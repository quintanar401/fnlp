class Trie:
    def __init__(self):
        self.root = {}
        self.total_len = 0
        self.len = 0
    def __len__(self):
        return self.total_len
    def __setitem__(self, item, data):
        dict = self.dict
        for c in item:
            if not c in dict:
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
        dict = self.dict
        for c in item:
            if c in dict:
                dict = dict[c]
            else:
                return []
        return dict["data"] if "data" in dict else []
    def __contains__(self, item):
        return len(self[item]) > 0
