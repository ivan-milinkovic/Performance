import Foundation
import OSLog

/*
 coords_10_000.json release
 
 JsonParserValues:   12_616_383 ticks, 525.68ms
 JsonParserUnicode    2_343_682 ticks,  97.65ms
 JsonParserAscii      2_339_993 ticks,  97.50ms
 JSONDecoder          1_856_054 ticks,  77.34ms
 JsonParserObjc       1_080_941 ticks,  45.04ms
 JsonParserObjcNoArc  1_000_709 ticks,  41.70ms
 JsonParserBuffers      941_253 ticks,  39.22ms
 JsonParserFopen        818_944 ticks,  34.12ms
 JsonParserCChar        817_413 ticks,  34.06ms
 JsonParserIndexes      445_691 ticks,  18.57ms
 JsonParserObjcC        389_813 ticks,  16.24ms
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
    698_234 ticks, 29.09ms - avoid using collection wrappers
    653_262 ticks, 27.22ms - use realloc instaed of pre-calculating and allocating the full array size
    553_015 ticks, 23.04ms - store NSData.length into a variable for a for loop
    425_235 ticks, 17.72ms - inline isWhitespace and isDelimiter
    389_813 ticks, 16.24ms - use C functions instead of ObjC methods (message sends)
 
 high %:
      Data iteration
      String / Character
      Array allocations / resizing
      Double parsing (default checks locales)
      Swift uses dynamically linked implementations, links to system libraries, DYLD-Stub
 */

func testJsonParser() {
    
    let runJsonParserValues    = false
    let runJsonParserUnicode   = false
    let runJsonParserAscii     = false
    let runJSONDecoder         = false
    let runJsonParserObjc      = false
    let runJsonParserObjcC     = true
    let runJsonParserObjcNoArc = false
    let runJsonParserBuffers   = false
    let runJsonParserFopen     = false
    let runJsonParserCChar     = false
    let runJsonParserIndexes   = false
    let runJSONSerialization   = false
    
//    let jsonFile = "testJson.json"
    let jsonFile = "coords_10_000.json"
    let inputFileUrl = dataDirUrl.appending(path: jsonFile, directoryHint: URL.DirectoryHint.notDirectory)
    let signposter = OSSignposter()
    
    if runJsonParserObjc {
        let data = try! Data(contentsOf: inputFileUrl)
        let state = signposter.beginInterval("JsonParserObjc")
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserObjc()
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        signposter.endInterval("JsonParserObjc", state)
        print("JsonParserObjc:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }
    
    if runJsonParserObjcC {
        let data = try! Data(contentsOf: inputFileUrl)
        let state = signposter.beginInterval("JsonParserObjcC")
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserObjcC()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        signposter.endInterval("JsonParserObjcC", state)
        print("JsonParserObjcC:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of: res))
    }
    
    if runJsonParserIndexes {
        let data = try! Data(contentsOf: inputFileUrl)
        let state = signposter.beginInterval("JsonParserIndexes")
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserIndexes()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        signposter.endInterval("JsonParserIndexes", state)
        print("JsonParserIndexes:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of: res))
    }
    
    if runJsonParserObjcNoArc {
        let data = try! Data(contentsOf: inputFileUrl)
        let state = signposter.beginInterval("JsonParserObjcNoArc")
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserObjcNoArc()
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        signposter.endInterval("JsonParserObjcNoArc", state)
        print("JsonParserObjcNoArc:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }
    
    if runJsonParserUnicode {
        var jsonString = try! String.init(contentsOf: inputFileUrl)
        jsonString.makeContiguousUTF8()
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserUnicode()
        let _ = jsonParser.parse(jsonString: jsonString)
        Profiler.end(0)
        print("JsonParserUnicode:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    if runJsonParserAscii {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserAscii()
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserAscii:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    if runJsonParserFopen {
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserFopen()
        let _ = jsonParser.parse(filePath: inputFileUrl.path())
        Profiler.end(0)
        print("JsonParserFopen:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    if runJsonParserCChar {
        let data = try! Data(contentsOf: inputFileUrl)
        let state = signposter.beginInterval("JsonParserCChar")
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserCChar()
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        signposter.endInterval("JsonParserCChar", state)
        print("JsonParserCChar:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }
    
    if runJsonParserBuffers {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserBuffers()
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserBuffers:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    if runJsonParserValues {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserValues()
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserValues:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    if runJSONDecoder {
        let data = try! Data.init(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let _ = try! JSONDecoder().decode([[String:Double]].self, from: data)
        Profiler.end(0)
        print("JSONDecoder:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    if runJSONSerialization {
        let data = try! Data.init(contentsOf: inputFileUrl)
        let state = signposter.beginInterval("JSONSerialization")
        Profiler.reset()
        Profiler.start(0)
        let res = try! JSONSerialization.jsonObject(with: data)
        Profiler.end(0)
        signposter.endInterval("JSONSerialization", state)
        print("JSONSerialization:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of: res))
    }
    
}
