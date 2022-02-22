# Python-Scripts

## 处理json格式和转义UTC时间

```python
#!/usr/bin/env python
# -*- coding=utf-8
import os, re 
import json
import jsonpath
import datetime
import time

# 使UTC时间转换为本地时间
def utc2local(utc_st):
    now_stamp = time.time()
    local_time = datetime.datetime.fromtimestamp(now_stamp)
    utc_time = datetime.datetime.utcfromtimestamp(now_stamp)
    offset = local_time - utc_time
    local_st = utc_st + offset
    return local_st

# 处理json内容
def unicode_convert(input):
    if isinstance(input, dict):
        return {unicode_convert(key): unicode_convert(value) for key, value in input.iteritems()}
    elif isinstance(input, list):
        return [unicode_convert(element) for element in input]
    elif isinstance(input, unicode):
        return input.encode('utf-8')
    else:
        return input

if __name__ == '__main__':
    URL = "https://wallet.yottachain.net"
    INITIAL_VALUE = "0"
    bithumbyta15_full = 'cleos -u ' + URL + ' get actions bithumbyta15 ' + INITIAL_VALUE + ' 0 -j'
    #print bithumbyta15_full
    result = os.popen(bithumbyta15_full)
    res = result.read()
    json_loads = unicode_convert(json.loads(res))
    
    json_account_action_seq  = jsonpath.jsonpath(json_loads,"actions[0].account_action_seq")
    json_block_time = jsonpath.jsonpath(json_loads,"actions[0].block_time")
    json_receiver = jsonpath.jsonpath(json_loads,"actions.[]action_trace.receipt.receiver")
    json_account = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.account")
    json_name = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.name")
    json_from = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.data.from")
    json_to = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.data.to")
    json_quantity = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.data.quantity")
    json_memo = jsonpath.jsonpath(json_loads,"actions.[]action_trace.act.data.memo")
    
    UTC_FORMAT = "%Y-%m-%dT%H:%M:%S.%f"
    utc_time = datetime.datetime.strptime(json_block_time[0], UTC_FORMAT)
    local_time = utc2local(utc_time)
    
    print local_time.strftime("%Y-%m-%d,%H:%M:%S")
    
    print json_account_action_seq[0]
    print json_block_time[0]
    print json_receiver[0]
    print json_account[0]
    print json_name[0]
    print json_from[0]
    print json_to[0]
    print json_quantity[0]
    print json_memo[0]

```

