//
//  SwiftSpeed.swift
//  Performance
//
//  Created by Ivan Milinkovic on 24.6.23..
//

import Foundation

func testSwiftSpeed() {
    let N = 1000
    
    do {
        let ticks = measureTicks(epochs: N) {
            let e = Enum1.three
            let e2 = e
        }
        print(ticks)
    }
    
    do {
        let ticks = measureTicks(epochs: N) {
            let e = Enum2.three(123)
            let e2 = e
        }
        print(ticks)
    }
    
    do {
        let ticks = measureTicks(epochs: N) {
            let e = Enum1.three
            switch e {
            case .one:
                break
            case .two:
                break
            case .three:
                break
            }
        }
        print(ticks)
    }
    
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
