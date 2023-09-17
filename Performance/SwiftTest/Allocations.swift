//
//  Allocations.swift
//  Performance
//
//  Created by Ivan Milinkovic on 17.9.23..
//

import Foundation

func testAllocations() {
    
    do {
        Profiler.reset()
        Profiler.start(0)
        var array = Array<Dictionary<String, Double>>()
        var i = 0; while i < 10_000 {
            let d = ["lat1": 123.0, "lon": 234, "lat2": 123, "lon2": 234]
            array.append(d)
            i += 1
        }
        Profiler.end(0)
        print("Swift allocations:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", array.count)
    }
    
    do {
        Profiler.reset()
        Profiler.start(0)
        let array = NSMutableArray()
        var i = 0; while i < 10_000 {
            let d = NSMutableDictionary()
            d["lat1"] = 123.0
            d["lon"] = 234
            d["lat2"] = 123
            d["lon2"] = 234
            array.add(d)
            i += 1
        }
        Profiler.end(0)
        print("Obj allocations from Swift:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", array.count)
    }
    
    do {
        Profiler.reset()
        Profiler.start(0)
        let array = ObjcAllocations.allocate()
        Profiler.end(0)
        print("Swift allocations:", Profiler.ticks(0), "ticks,", Profiler.seconds(0).string, "res:", array.count)
    }
}
