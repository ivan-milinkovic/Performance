//
//  SwiftSpeed.swift
//  Performance
//
//  Created by Ivan Milinkovic on 24.6.23..
//

import Foundation

func testSwiftSpeed() {
    let epochs = 1000
    var t : Int = 0
    
    let n = 1000

    t = measureTicks(epochs: epochs) {
        var a = [Int]()
        var i = 0; while i < n {
            a.append(i)
            i += 1
        }
    }
    print("[Int]", t)

    t = measureTicks(epochs: epochs) {
        var a = [Int]()
        a.reserveCapacity(1000)
        var i = 0; while i < n {
            a.append(i)
            i += 1
        }
    }
    print("[Int] reserve:", t)

    t = measureTicks(epochs: epochs) {
        var a = ContiguousArray<Int>()
        var i = 0; while i < n {
            a.append(i)
            i += 1
        }
    }
    print("ContiguousArray:", t)

    t = measureTicks(epochs: epochs) {
        var a = [Int].init(repeating: 0, count: 1000)
        var i = 0; while i < n {
            a[i] = i
            i += 1
        }
    }
    print("[Int].repeating:", t)
    
    
    // while vs forEach
    
    t = measureTicks(epochs: epochs) {
        let a = [Int].init(repeating: 2, count: 1000)
        var i = 0; while i < n { defer { i += 1 }
            let _ = a[i]
        }
    }
    print("[Int] while:", t)

    t = measureTicks(epochs: epochs) {
        let a = [Int].init(repeating: 2, count: 1000)
        a.forEach { i in
            let _ = a[i]
        }
    }
    print("[Int] forEach:", t)
}

private enum Enum1 {
    case one
    case two
    case three
}

private enum Enum2 {
    case one(Int)
    case two(Int)
    case three(Int)
}

private func measureTicks(epochs: Int, task: () -> Void) -> Int {
    var i = 0
    var t0 : UInt64 = 0
    var sum : UInt64 = 0
    while i < epochs {
        t0 = mach_absolute_time()
        task()
        sum += mach_absolute_time() - t0
        i += 1
    }
    let avg = Double(sum) / Double(i-1)
    return Int(avg)
}
