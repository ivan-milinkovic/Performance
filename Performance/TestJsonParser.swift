//
//  TestJsonParser.swift
//  Performance
//
//  Created by Ivan Milinkovic on 24.6.23..
//

import Foundation

/*
 Ticks:
 2_957_556 - JsonParserUnicode
 1_777_051 - JSONDecoder
 1_472_220 - JsonParserBuffers
 1_104_004 - JsonParserCChar - use chars instead of strings
   938_272 - JsonParserCChar - avoid string concatenation
   925_551 - JsonParserCChar - reserve capacity
   835_231 - JsonParserFopen - use FileDataIterator - a buffered wrapper around fopen, fread to iterate
   814_161 - JsonParserFopen - fopen, fread and buffering inline
   176_323 - JSONSerialization - objective-c
 
 high %:
      Array allocations / resizing
      Double parsing (default checks locales)
      String uses dynamically linked implementation, links to system library, DYLD-Stub
 */

func testJsonParser() {
    
//    let jsonFile = "testJson.json"
    let jsonFile = "coords_10_000.json"
    let inputFileUrl = dataDirUrl.appending(path: jsonFile, directoryHint: URL.DirectoryHint.notDirectory)
    
//    do {
//        let t0 = mach_absolute_time()
//        var jsonString = try! String.init(contentsOf: inputFileUrl)
//        jsonString.makeContiguousUTF8()
//        let jsonParser = JsonParserUnicode()
//        jsonParser.log = false
//        let _ = jsonParser.parse(jsonString: jsonString)
//        let t1 = mach_absolute_time() - t0
//        print(String(format: "%8d", t1))
//        // 2_957_556 ticks release
//    }
    
//    do {
//        let t0 = mach_absolute_time()
//        let data = try! Data(contentsOf: inputFileUrl)
//        let jsonParser = JsonParserAscii()
//        jsonParser.log = false
//        let _ = jsonParser.parse(data: data)
//        let t1 = mach_absolute_time() - t0
//        print(String(format: "%8d", t1))
//    }
    
//    do {
//        let t0 = mach_absolute_time()
//        let data = try! Data(contentsOf: inputFileUrl)
//        let jsonParser = JsonParserCChar()
//        jsonParser.log = false
//        let _ = jsonParser.parse(data: data)
//        let t1 = mach_absolute_time() - t0
//        print(String(format: "%8d", t1))
//        // release:
//        // 1104004 ticks - use chars
//        //  938272 - avoid string concatenation
//        //  925551 - reserve capacity
//    }
    
//    do {
//        let t0 = mach_absolute_time()
//        let jsonParser = JsonParserFopen()
//        jsonParser.log = false
//        let j = jsonParser.parse(filePath: inputFileUrl.path())
//        print(j)
//        let t1 = mach_absolute_time() - t0
//        print(String(format: "%8d", t1))
//        // 835_231 ticks release
//    }
    
    do {
        let t0 = mach_absolute_time()
        let jsonParser = JsonParserBuffers()
        jsonParser.log = false
        let _ = jsonParser.parse(filePath: inputFileUrl.path())
        let t1 = mach_absolute_time() - t0
        print(String(format: "%8d", t1))
        // 1_472_220 ticks release
    }
    
//    do {
//        let t0 = mach_absolute_time()
//        let data = try! Data.init(contentsOf: inputFileUrl)
//        let _ = try! JSONDecoder().decode([[String:Double]].self, from: data)
//        let t1 = mach_absolute_time() - t0
//        print(String(format: "%8d", t1))
//        // 1_777_051 ticks release
//    }
//
//    do {
//        let t0 = mach_absolute_time()
//        let data = try! Data.init(contentsOf: inputFileUrl)
//        let _ = try! JSONSerialization.jsonObject(with: data)
//        let t1 = mach_absolute_time() - t0
//        print(String(format: "%8d", t1))
//        // 176_323 ticks release
//    }
    
}
