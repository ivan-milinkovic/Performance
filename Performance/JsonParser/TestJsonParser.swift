import Foundation
import OSLog

func testJsonParser() {
    
    let runJsonParserValues    = false
    let runJsonParserUnicode   = false
    let runJsonParserAscii     = false
    let runJSONDecoder         = false
    let runJSONSerialization   = false
    let runJsonParserObjc      = false
    let runJsonParserBuffers   = false
    let runJsonParserFopen     = false
    let runJsonParserCChar     = false
    let runJsonParserIndexes   = false
    let runJsonParserObjcNoArc = false
    let runJsonParserObjcC     = true
    let runJsonParserOneIter   = true
    let runJsonParserOneIter2  = true
    
//    let jsonFile = "testJson.json"
    let jsonFile = "coords_10_000.json"
    let inputFileUrl = dataDirUrl.appending(path: jsonFile, directoryHint: URL.DirectoryHint.notDirectory)
    let signposter = OSSignposter()
    
    if runJsonParserOneIter {
        let str = try! String(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserOneIter()
        let res = jsonParser.parse(string: str)
        Profiler.end(0)
        print("JsonParserOneIter:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
    }
    
    if runJsonParserOneIter2 {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserOneIter2()
        let res = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserOneIter2:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", type(of:res))
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
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        signposter.endInterval("JsonParserObjc", state)
        print("JsonParserObjc:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
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
