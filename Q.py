import asyncore, socket, struct, datetime

class Hopen(asyncore.dispatcher):
    def __init__(self, host, port, username = "", password = None):
        asyncore.dispatcher.__init__(self)
        self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
        self.connect( (host, port) )
        self.buffer = (username+":"+password if password else username).encode()+b"\x03\x00"

    def handle_connect(self):
        print("connect")

    def handle_close(self):
        print("close")
        self.close()

    def handle_error1(self):
        print("error")

    def handle_read(self):
        print(self.recv(8192))

    def writable(self):
        return (len(self.buffer) > 0)

    def handle_write(self):
        sent = self.send(self.buffer)
        self.buffer = self.buffer[sent:]

    def __call__(self, arg):
        if isinstance(arg, str):
            self.buffer = arg.encode()

# struct fmt for q types
q2struct = ["", "?", "", "", "B", "h", "i", "q", "f", "d", "c", "", "q", "i", "i", "d", "q", "i", "i", "i"]
# q obj size
q2size = [0,1,16,0,1,2,4,8,4,8,1,1,8,4,4,8,8,4,4,4]
# q function names
q2unary = ['::','flip','neg','first','reciprocal','where','reverse','null','group','hopen','hclose',
    'string','enlist','count','floor','not','key','distinct','type','value','read0','read1','2::',
    'avg','last','sum','prd','min','max','exit','getenv','abs',"sqrt","log","exp","sin","asin","cos","acos","tan","atan","enlist","var","dev"]
q2binary = [':','+','-','*','%','&','|','^','=','<','>','$',',','#','_','~','!','?','@','.','0:',
    '1:','2:','in','within','like','bin','ss','insert','wsum','wavg','div',"xexp","setenv","binr","cov","cor"]
# adverbs
q2adv = ["'","/","\\","':","/:","\\:"]
# attributes
q2attr = 'supg'
q2battr = { "s": 1, "u": 2, "p": 3, "g": 4, "": 0 }

def lst2py(value):
    return [py(i) for i in value[2]]
def ts2datetime(value):
    if value is nj:
        return None
    value = (value/8.64e13+10957)*8.64e4
    if value < 0:
        return datetime.datetime.utcfromtimestamp(0)
    return datetime.datetime.utcfromtimestamp(value)
def datetime2ts(value):
    value = (value - datetime.datetime(1970,1,1)).total_seconds()
    return int(1000000000*(value-10957*86400))
def dt2datetime(value):
    if value < -10957:
        return datetime.datetime.utcfromtimestamp(0)
    return datetime.datetime.utcfromtimestamp(86400*(10957+value))
def datetime2dt(value):
    value = (value - datetime.datetime(1970,1,1)).total_seconds()
    return value/86400- 10957
def m2date(value):
    if value is ni:
        return None
    elif value is nwi:
        return nwm
    elif value <= -24000 + 12:
        return nnwm
    m = value + 24000; y = m // 12
    return datetime.date(y, 1 + m % 12, 1)
def dt2date(value):
    if value is ni:
        return None
    elif value is nwi:
        return nwd
    elif value < -730119:
        return nnwd
    return datetime.date.fromordinal(value+730120)
def ts2delta(value):
    value = value // 1000
    if value < 0:
        days = -(1 + (-value) // 86400000000)
        value = (-days) * 86400000000 + value
    else:
        days = value // 86400000000
        value = value % 86400000000
    mcs = value % 1000000; value = value // 1000000
    sec = value % 60; value = value // 60
    min = value % 60; value = value // 60
    return datetime.timedelta(days, sec, mcs, 0, min, value)
def min2time(value):
    if value is ni:
        return None
    elif value < 1 or v >= 1440:
        return None
    return datetime.time(value // 60, value % 60)
def sec2time(value):
    if value is ni:
        return None
    elif value < 1 or v >= 86400:
        return None
    return datetime.time(value // 3600, (value // 60) % 60, value % 60)
def tm2time(value):
    if value is ni:
        return None
    elif value < 1 or v >= 86400000:
        return None
    mcs = 1000*(value % 1000); value = value // 1000
    return datetime.time(value // 3600, (value // 60) % 60, value % 60)
def pystr(str):
    try:
        str = str.decode()
    except:
        pass
    return str
def dict2py(value):
    k = py(value[1]); v = py(value[2])
    if value[1][0] is 98:
        return { "key": k, "value": v}
    if value[2][0] is -11:
        v = [v] * len(k)
    return(dict(zip(k,v)))
def py(msg):
    ty = msg[0]
    return qa2py[-ty](msg[1]) if ty < 0 else q2py[ty](msg)

ni = -2147483648 # i,m,v,t,d
nwi = 2147483647 # -nw = neg nw
nj = 9223372036854775808
nwj = 9223372036854775807
nwp = ts2datetime(nwj)
nwm = datetime.date(datetime.MAXYEAR,12,1)
nnwm = datetime.date(datetime.MINYEAR,12,1)
nwd = datetime.date(datetime.MAXYEAR,12,31)
nnwd = datetime.date(datetime.MINYEAR,12,31)
nf = float('nan')
nwf = float('inf')

# pytonifiers
q2apy = ([lambda x: x] * 10) + [
    pystr(x), # char
    pystr(x), # symbol
    ts2datetime(x), # timestamp
    m2date(x), # month
    dt2date(x), # date
    dt2datetime(x), # datetime
    ts2delta(x), # timespan
    min2time(x), # minute
    sec2time(x), # second
    tm2time(x), # time
    ]
q2py = [lst2py] * 129
q2py[10] = lambda x: pystr(x[2])
q2py[11] = lambda x: [pystr(i) for i in x[2]]
q2py[98] = lambda x: dict2py(x[1])
q2py[99] = dict2py
q2py[100] = lambda x: pystr(x[2])
q2py[101] = lambda x: None if x[1] is 255 else q2unary[x[1]]
q2py[102] = lambda x: q2binary[x[1]]
q2py[103] = lambda x: q2adv[x[1]]
q2py[104] = lambda x: [py(i) for i in x[1]]
q2py[105] = q2py[104]
q2py[106:112] = [lambda x: (q2adv[x[0]-106],py[x[1]])] * 6
q2py[128] = lambda x: raise KException(pystr(x[1]))

class QMessage:
    def __init__(self, msg, msg_type = 1):
        self.msg = msg
        self.i = 0
        self.fmt = ">"
        self.msg_type = msg_type
        self.compressed = 0
    def size(self, msg):
        ty = msg[0]
        if ty < 0
            if ty is -11:
                return 2 + len(msg[1])
            return 1 + q2size[-ty]
        if ty < 20:
            if ty is 0:
                return 6 + sum(map(lambda x: self.size(x), msg[2]))
            if ty is 11:
                return 6 + sum(map(lambda x: 1+len(x), msg[2]))
            return 6 + len(msg[2]) * q2size[ty]
        if ty is 98:
            return 2 + self.size(msg[2])
        if ty in [99,127]:
            return 1 + self.size(msg[1]) + self.size(msg[2])
        if ty is 100:
            return 2 + len(msg[1]) + self.size(msg[2])
        if ty < 104:
            return 2
        if ty < 106:
            return 5 + sum(map(lambda x: self.size(x), msg[1]))
        if ty < 112:
            return 1 + self.size(msg[1])
        if ty is 128:
            return 2 + len(msg[1])
        raise QException("Unknown Q type: "+ty)
    def write(self, typ, value):
        struct.pack_into(self.fmt+q2struct[typ], self.msg, self.i, value)
        self.i += q2size[typ]
    def write_sym(self, sym):
        self.write_str(sym)
        self.write(4, 0)
    def write_str(self, sym):
        self.msg[self.i:self.i+len(sym)] = sym
        self.i = self.i + len(sym)
    def write_header(self, msg):
        l = msg.size() + 8
        self.msg = bytearray(l)
        self.write(4, 1); self.write(4, self.msg_type)
        self.write(5, 0); self.write(6, l)
    def write_msg(self, msg):
        self.write_header(msg)
        self.write_val(msg)
    def write_val(self, msg):
        ty = msg[0]
        self.write(4, ty if ty >=0 else 256 + ty)
        if ty in [-11, 128]:
            return self.write_sym()
        if ty < 0:
            if ty in [-2, -10]:
                return self.write_str(msg[1])
            return self.write(-ty, msg[1])
        if ty < 20:
            self.write(4, msg[1]); self.write(6, len(msg[2]))
            if ty is 0:
                return [self.write_val(i) for i in msg[2]]
            if ty is 10:
                return self.write_str(msg[2])
            if ty is 11:
                return [self.write_sym(i) for i in msg[2]]
            if ty is 2:
                return [self.write_str(i) for i in msg[2]])
            return [self.write(typ, i) for i in msg[2]]
        if ty is 98:
            self.write(4, msg[1])
            return self.write_val(msg[2])
        if ty in [99,127]:
            self.write_val(msg[1])
            return self.write_val(msg[2])
        if ty is 100:
            self.write_sym(msg[1])
            return self.write_val(msg[2])
        if ty < 104:
            return self.write(4, msg[1])
        if ty < 106:
            return [self.write_val(i) for i in msg[1]]
        if ty < 112:
            return self.write_val(msg[1])
        raise QException("Unknown Q type: "+ty)

    def read(self, typ):
        v = struct.unpack_from(self.fmt+q2struct[typ], self.msg, self.i)
        self.i += q2size[typ]
        return v
    def read_sym(self):
        i = self.i
        while self.msg[i]>0:
            i += 1
        res = self.msg[self.i:self.i+i]
        self.i = i +1
        return res
    def read_str(self, l):
        res = self.msg[self.i:self.i+l]
        self.i += l
        return res
    def read_header(self):
        if len(self.msg) < 9:
            raise QException("Invalid message")
        self.i = 4
        self.fmt = ">" if self.msg[0] else "<"
        self.msg_type = self.msg[1]
        self.compressed = self.msg[2]
        return self.read(6)
    def read_msg(self, fmt = "py"):
        self.i = 0
        l = self.read_header()
        if l is not len(self.msg):
            raise QException("Invalid message length")
        if self.compressed:
            self.uncompress()
        return self.read_val()
    def read_val(self):
        ty = self.read(4)
        if ty > 236:
            ty = ty-256
            if ty is -10:
                return (ty, self.read_str(1))
            if ty is -11:
                return (ty, self.read_sym())
            if ty is -2:
                return (ty, self.read_str(16))
            return (ty, self.read(-ty))
        if ty < 20:
            a = self.read(4); l = self.read(6)
            if ty is 0:
                return (0, a, [self.read_val() for i in range(l)])
            if ty is 10:
                return (10, a, self.read_str(l))
            if ty is 11:
                return (11, a, [self.read_sym() for i in range(l)])
            if ty is 2:
                return (11, a, [self.read_str(16) for i in range(l)])
            return (ty, a, [self.read(typ) for i in range(l)])
        if ty is 98:
            return (98, self.read(4), self.read_val())
        if ty in [99,127]:
            return (ty, self.read_val(), self.read_val())
        if ty is 100:
            return (100, self.read_sym(), self.read_val())
        if ty < 104:
            return (ty, self.read(4))
        if ty < 106:
            return (104, [self.read_val() for i in range(self.read(6))])
        if ty < 112:
            return (ty, self.read_val())
        if ty is 128:
            return (128, self.read_str())
        return (10, 0, "unknown Q type: " + str(ty))
    def uncompress(self):
        dst = bytearray(self.read(6))
        aa = [0] * 256
        s = p = 8; ii = f = r = n = 0; d = self.i
        b = self.msg
        while s < len(dst):
            if ii is 0:
                f = 0xff & b[d]; ii = 1; d += 1
            if (f & ii) is not 0:
                r = aa[0xff & b[d]]; d += 1
                dst[s] = dst[r]; s += 1; r += 1
                dst[s] = dst[r]; s += 1; r += 1
                n = 0xff & b[d]; d += 1
                if n>0:
                    for m in range(n):
                        dst[s+m] = dst[r+m]
            else:
                dst[s] = b[d]; s += 1; d += 1
            while p < s-1:
                aa[(0xff & dst[p]) ^ (0xff & dst[p+1])] = p; p += 1
            if (f&ii) is not 0:
                p = s += n
            ii *= 2
            if ii is 256:
                ii = 0
        self.msg = dst
        self.i = 8

class QException(BaseException):
    pass

class KException(BaseException):
    pass

def encode_type(obj):
    if type(obj) is tuple:
        return obj[0]
    if type(obj) is int:
        return -6
    if type(obj) is float:
        return -7
    if type(obj) is bool:
        return -1
    if type(obj) is str or type(obj) is unicode:
        return 10
    if type(obj) is bytes:
        return -11
    if type(obj) is dict:
        if len(obj) is 0:
            return 99
        if not all(map(lambda x: encode_type(x) in [10, -11], obj.keys())):
            return 99
        l = len(obj.values()[0])
        for i in obj.values():
            if type(i) is not list or len(i) is not l:
                return 99
        return 98
    if type(obj) is list:
        if len(obj) is 0:
            return 0
        t = encode_type(obj[0])
        if t >= 0:
            return 0
        for i in lst:
            if encode_type(i) is not t:
                return 0
        return t
    if type(obj) is datetime.datetime:
        return -12
    if type(obj) is datetime.date:
        return -14
    if type(obj) is datetime.timedelta:
        return -16
    if type(obj) is datetime.time:
        return -19
def q_list(type_fn, value, attr=""):
    if not type(value) is list:
        raise QException("List is expected")
    if type(type_fn) is int:
        typ = type_fn; type_fn = qcontr[qcontr.index(type_fn)]
    else:
        typ = qcontr.index(type_fn)
    return (typ, q2battr[attr], [type_fn(i) for i in value])
def q_uuid(value, attr = ""):
    if not type(value) is bytes:
        value = value.encode()
    return (-2, value)
def q_time(value):
    if type(value) is tuple:
        value = datetime.time(*value)
    if type(value) is datetime.time:
        value = value.hour*3600000 + value.minute*60000 + value.second*1000 + value.microsecond // 1000
    return value
