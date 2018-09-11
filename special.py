def get_special_rules():
    m = list(map(lambda x: (x+"s",[{ORTH: x+"s", LEMMA: x}]), [
        u"rateset", u"ip", u"jira", u"cronjob", u"fid", u"ric", u"hdb", u"cron", u"crontab", u"rdb", u"gw", u"csv"
    ]))
    return [(u"permissioned",[{ORTH: u"permissioned", LEMMA: u"permission"}])] + m
