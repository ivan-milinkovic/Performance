

Debugger:
```
p ((__bridge OCCToken*)ocarray_get(&tokens, 0))->index
p ((__bridge OCCToken*)ocarray_get(&tokens, 0))->length
p (*((__bridge OCCToken**)ocarray_get(&tokens, 0)))->index
po [[NSString alloc] initWithBytes:(bytes + currentToken->index) length:currentToken->length encoding:NSUTF8StringEncoding];
```


Signposts in ObjC:
```
os_log_t log = os_log_create("parser", OS_LOG_CATEGORY_POINTS_OF_INTEREST);
os_signpost_id_t sid = os_signpost_id_generate(log);
os_signpost_interval_begin(log, sid, "collections");
os_signpost_interval_end(log, sid, "collections");
```


Test json:
```
let str = #"{"key":"val"}"#
let str = #"["123", 234, 345]"#
let str = #"[ { "lat1": 123.0, "lon": 234, "lat2": 123, "lon2": 234} ]"#
let str = #"[{"lat1": 123.0}]"#
```
