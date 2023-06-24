//
//  TestJsonParser.swift
//  Performance
//
//  Created by Ivan Milinkovic on 24.6.23..
//

import Foundation

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
    
    do {
        let t0 = mach_absolute_time()
        let data = try! Data(contentsOf: inputFileUrl)
        let jsonParser = JsonParserCChar()
        jsonParser.log = false
        let _ = jsonParser.parse(data: data)
        let t1 = mach_absolute_time() - t0
        print(String(format: "%8d", t1))
        // 1104004 - release
        //  938272 - release
        //  176323 - NSSerialization
    }
    
//    do {
//        let t0 = mach_absolute_time()
//        let data = try! Data.init(contentsOf: inputFileUrl)
//        let _ = try! JSONDecoder().decode([[String:Double]].self, from: data)
//        let t1 = mach_absolute_time() - t0
//        print(String(format: "%8d", t1))
//    }
//
//    do {
//        let t0 = mach_absolute_time()
//        let data = try! Data.init(contentsOf: inputFileUrl)
//        let _ = try! JSONSerialization.jsonObject(with: data)
//        let t1 = mach_absolute_time() - t0
//        print(String(format: "%8d", t1))
//    }
    
}
