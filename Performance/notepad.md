
Results:
```
coords_10_000.json release

JsonParserValues    12_616_383 ticks, 525.68ms
JsonParserOneIter    7_394_511 ticks, 308.10ms
JsonParserUnicode    2_343_682 ticks,  97.65ms
JsonParserAscii      2_339_993 ticks,  97.50ms
JSONDecoder          1_856_054 ticks,  77.34ms
JsonParserObjc       1_080_941 ticks,  45.04ms
JsonParserObjcNoArc  1_000_709 ticks,  41.70ms
JsonParserBuffers      941_253 ticks,  39.22ms
JsonParserFopen        818_944 ticks,  34.12ms
JsonParserCChar        817_413 ticks,  34.06ms
JsonParserIndexes      445_691 ticks,  18.57ms
JsonParserObjcC        321_424 ticks,  13.39ms
JSONSerialization      164_948 ticks,   6.87ms


JsonParserUnicode:
  2_343_682 ticks, 97.65ms - use native swift data structures freely

JsonParserCChar:
  1_104_004 - use chars instead of strings (moving from JsonParserUnicode)
  938_272 - avoid string concatenation
  925_551 - reserve capacity
  877_290 - use BufferedDataReader
  854_368 - copy all bytes from Data into a pointer memory

JsonParserIndexes:
  514_022 ticks, 21.42ms - use indexes into original data instead of copying data chunks into tokens (moving from JsonParserCChar)
  486_076 ticks, 20.25ms - use Array.reserveCapacity(20)
  445_691 ticks, 18.57ms - use Array.reserveCapacity(5)

JsonParserObjc
  1_386_492 ticks, 57.77ms
  1_362_449 ticks, 56.77ms - use __unsafe_unretained for method parameters, avoids retain calls
  1_314_763 ticks, 54.78ms - avoid type checking ([obj isKindOf:]), just dispatch a known selector ([obj consume:])
  1_124_139 ticks, 46.84ms - remove some type check validations that are replaced with selector calls
  1_080_941 ticks, 45.04ms - exclude validations from release (#ifdef DEBUG)

JsonParserObjcC
  1_771_327 ticks, 73.81ms - initial C implementation with array resizing (time lost in repeated mallocs and memmove)
  674_234 ticks, 28.09ms - precalculate safe size for token array based on input data size (avoid malloc)
  698_234 ticks, 29.09ms - avoid using collection wrappers (JsonMap, JsonArray, avoids extra allocations/deallocations)
  653_262 ticks, 27.22ms - use realloc instaed of pre-calculating and allocating the full array size
  553_015 ticks, 23.04ms - store NSData.length into a variable for a for loop
  425_235 ticks, 17.72ms - inline isWhitespace and isDelimiter
  389_813 ticks, 16.24ms - use C functions instead of ObjC methods (avoid message sends)
  372_133 ticks, 15.51ms - extract token parsing to a function
                         - Moving value parsing inside pareCollections (avoid extra loop through tokens) gave no benefit
  353_555 ticks, 14.73ms - disable ARC
  321_424 ticks, 13.39ms - avoid calling pow()

JsonParserOneIter:
  6_334_768 ticks, 263.95ms - initial using swift standard library
JsonParserOneIter2:
  1_826_720 ticks,  76.11ms - use Data iterator instead of String iterator
  1_446_843 ticks,  60.29ms - avoid appending to string, use index and length and resolve value at the end


high %:
    Data iteration
    String / Character
    Array allocations / resizing
    Double parsing (default checks locales)
    Swift uses dynamically linked implementations, links to system libraries, DYLD-Stub

todo:
    disable arc for shared.m, and test if other parsers still work
    try C bitfield in token
```

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
