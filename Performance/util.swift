//
//  Util.swift
//  Performance
//
//  Created by Ivan Milinkovic on 3.6.23..
//

import Foundation

extension ContinuousClock.Instant.Duration {
    
    var seconds: Double {
        let (s, attos) = self.components // attos = 10e-18
        let millis = Double(attos) / 1_000_000_000_000_000_000
        return Double(s) + millis
    }
    
    var millis: Double {
        let (s, attos) = self.components // attos = 10e-18
        let millis = Double(attos) / 1_000_000_000_000_000
        return Double(s) + millis
    }
    
    var string: String {
        timeString(millis / 1_000)
    }
}

func timeString(_ s: Double) -> String {
    if floor(s) != 0 {
        return String(format: "%.2fs", s)
    }
    let ms = s * 1_000
    if floor(ms) != 0 {
        return String(format: "%.2fms", ms)
    }
    let us = ms * 1_000
    if floor(us) != 0 {
        return String(format: "%.2fus", us)
    }
    let ns = us * 1_000
    return String(format: "%.2fns", ns)
}

extension UInt8 {
    var binStr : String {
        binstr(self)
    }
}

extension UInt16 {
    var binStr : String {
        binstr(self)
    }
}

func binstr<T: BinaryInteger> (_ val: T, padding: Int = 0) -> String {
    let numBits = 8 * MemoryLayout<T>.size
    var chars = [Character].init(repeating: "0", count: numBits)
    for i in 0...numBits {
        if (val & (1 << (numBits - 1 - i))) != 0 {
            chars[i] = "1"
        }
    }
    
    if padding == 0 {
        return String(chars)
    }
    
    guard let i = chars.firstIndex(of: "1") else {
        return String(chars.suffix(padding))
    }
    
    let si = min(i, numBits - padding)
    return String(chars.suffix(from: si))
}

extension Data {
    var binStr : String {
        var str = ""
        for b in self {
            str.append(b.binStr)
            str.append(" ")
        }
        return str
    }
}

class Stack<T> {
    private var contents = [T]()
    
    func push(_ val: T) {
        contents.append(val)
    }
    
    func pop() -> T {
        contents.removeLast()
    }
    
    func top() -> T? {
        contents.last
    }
    
    var count: Int {
        contents.count
    }
}
