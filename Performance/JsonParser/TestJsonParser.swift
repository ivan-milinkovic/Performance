//
//  TestJsonParser.swift
//  Performance
//
//  Created by Ivan Milinkovic on 24.6.23..
//

import Foundation
import OSLog

/*
 coords_10_000.json release
 
 JsonParserValues: 12_616_383 ticks, 525.68ms
 JsonParserUnicode  2_343_682 ticks, 97.65ms
 JsonParserAscii    2_339_993 ticks, 97.50ms
 JSONDecoder        1_856_054 ticks, 77.34ms
 JsonParserBuffers    941_253 ticks, 39.22ms
 JsonParserFopen      818_944 ticks, 34.12ms
 JsonParserCChar      817_413 ticks, 34.06ms
 JSONSerialization    164_948 ticks,  6.87ms
 
 
 JsonParserCChar:
 1_104_004 - use chars instead of strings
   938_272 - avoid string concatenation
   925_551 - reserve capacity
   877_290 - use BufferedDataReader
   854_368 - copy all bytes from Data into a pointer memory
 
 high %:
      Data iteration
      String / Character
      Array allocations / resizing
      Double parsing (default checks locales)
      Swift uses dynamically linked implementations, links to system libraries, DYLD-Stub
 */

func testJsonParser() {
    
//    let jsonFile = "testJson.json"
    let jsonFile = "coords_10_000.json"
    let inputFileUrl = dataDirUrl.appending(path: jsonFile, directoryHint: URL.DirectoryHint.notDirectory)
    let signposter = OSSignposter()
    
    do {
        var jsonString = try! String.init(contentsOf: inputFileUrl)
        jsonString.makeContiguousUTF8()
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserUnicode()
        let _ = jsonParser.parse(jsonString: jsonString)
        Profiler.end(0)
        print("JsonParserUnicode:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    do {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserAscii()
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserAscii:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    do {
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserFopen()
        let _ = jsonParser.parse(filePath: inputFileUrl.path())
        Profiler.end(0)
        print("JsonParserFopen:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    do {
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
    
    do {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserBuffers()
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserBuffers:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    do {
        let data = try! Data(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let jsonParser = JsonParserValues()
        let _ = jsonParser.parse(data: data)
        Profiler.end(0)
        print("JsonParserValues:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    do {
        let data = try! Data.init(contentsOf: inputFileUrl)
        Profiler.reset()
        Profiler.start(0)
        let _ = try! JSONDecoder().decode([[String:Double]].self, from: data)
        Profiler.end(0)
        print("JSONDecoder:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }

    do {
        let data = try! Data.init(contentsOf: inputFileUrl)
        let state = signposter.beginInterval("JSONSerialization")
        Profiler.reset()
        Profiler.start(0)
        let _ = try! JSONSerialization.jsonObject(with: data)
        Profiler.end(0)
        signposter.endInterval("JSONSerialization", state)
        print("JSONSerialization:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string)
    }
    
}
