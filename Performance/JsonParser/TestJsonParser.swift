import Foundation
import OSLog

func testJsonParser() {
    let ws = false // removes compiler warnings for unreachable code
    let runJsonParserValues         = ws || false
    let runJsonParserUnicode        = ws || false
    let runJsonParserAscii          = ws || false
    let runJSONDecoder              = ws || false
    let runJsonParserObjc           = ws || false
    let runJsonParserBuffers        = ws || false
    let runJsonParserFopen          = ws || false
    let runJsonParserCChar          = ws || false
    let runJsonParserObjcNoArc      = ws || false
    let runJsonParserIndexes        = ws || false
    let runJsonParserObjcC          = ws || false
    let runJsonParserOneIter        = ws || false
    let runJsonParserOneIterCChar   = ws || false
    let runJSONSerialization        = ws || true
    let runJsonParserCRecursive     = ws || true
    let runJsonParserSwiftRecursive = ws || true
    
//    let jsonFile = "testJson.json"
    let jsonFile = "coords_10_000.json"
    let inputFileUrl = dataDirUrl.appending(path: jsonFile, directoryHint: URL.DirectoryHint.notDirectory)
    let signposter = OSSignposter()
    
    if runJsonParserSwiftRecursive {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserSwiftRecursive()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserSwiftRecursive:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }
    
    if runJsonParserCRecursive {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserCRecursive()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserCRecursive:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }
    
    if runJsonParserOneIter {
        let str = try! String(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserOneIter()
        let res = jsonParser.parse(string: str)
        Profiler.end(0)
        print("JsonParserOneIter:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }
    
    if runJsonParserOneIterCChar {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserOneIterCChar()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserOneIterCChar:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
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
    
    if runJsonParserObjc {
        let data = try! Data(contentsOf: inputFileUrl)
        let state = signposter.beginInterval("JsonParserObjc")
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserObjc()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        signposter.endInterval("JsonParserObjc", state)
        print("JsonParserObjc:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
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
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        signposter.endInterval("JsonParserObjcNoArc", state)
        print("JsonParserObjcNoArc:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }
    
    if runJsonParserUnicode {
        var jsonString = try! String.init(contentsOf: inputFileUrl)
        jsonString.makeContiguousUTF8()
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserUnicode()
        let res = jsonParser.parse(jsonString: jsonString)
        Profiler.end(0)
        print("JsonParserUnicode:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }

    if runJsonParserAscii {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserAscii()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserAscii:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }

    if runJsonParserFopen {
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserFopen()
        let res = jsonParser.parse(filePath: inputFileUrl.path())
        Profiler.end(0)
        print("JsonParserFopen:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }

    if runJsonParserCChar {
        let data = try! Data(contentsOf: inputFileUrl)
        let state = signposter.beginInterval("JsonParserCChar")
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserCChar()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        signposter.endInterval("JsonParserCChar", state)
        print("JsonParserCChar:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }
    
    if runJsonParserBuffers {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserBuffers()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserBuffers:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }

    if runJsonParserValues {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserValues()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserValues:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }

    if runJSONDecoder {
        let data = try! Data.init(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let res = try! JSONDecoder().decode([[String:Double]].self, from: data)
        Profiler.end(0)
        print("JSONDecoder:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
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
