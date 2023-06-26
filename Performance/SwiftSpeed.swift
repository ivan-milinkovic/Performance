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
    
//    let jsonFile = "coords_1_000.json"
//    let fileUrl = dataDirUrl.appending(path: jsonFile, directoryHint: URL.DirectoryHint.notDirectory)
//
//    t = measureTicks(epochs: epochs) {
//        let data = try! Data(contentsOf: fileUrl)
//        var iter = data.makeIterator()
//        while let b = iter.next() {
//            let _ = b
//        }
//    }
//    print("data iter:", t)
//
//    t = measureTicks(epochs: epochs) {
//        let data = NSData(contentsOf: fileUrl)!
//        var i = 0; while i < data.count { defer { i += 1 }
//            let _ = data[i]
//        }
//    }
//    print("nsdata:", t)
//
//    t = measureTicks(epochs: epochs) {
//        let data = try! Data(contentsOf: fileUrl)
//        data.forEach { b in
//            let _ = b
//        }
//    }
//    print("data forEach:", t)

//    t = measureTicks(epochs: epochs) {
//        let data = try! Data(contentsOf: fileUrl)
//        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
//            var i = 0; while i < data.count { defer { i += 1 }
//                let _ = data[i]
//            }
//        }
//    }
//    print("data ptr:", t)
//
//    // buffer of:
//    // 5 equals swifts Data performance
//    // 1MB (1_000_000) ~ 800 ticks
//    // 2MB (2_000_000) ~ 2000 ticks allocation overhead
//    t = measureTicks(epochs: epochs) {
//        let file = fopen(fileUrl.path(), "r")!
//        defer { fclose(file) }
//        let buffSize = 1_000_000
//        let buff = UnsafeMutableRawPointer.allocate(byteCount: buffSize, alignment: 1)
//        defer { buff.deallocate() }
//
//        while true {
//            let numread = fread(buff, 1, buffSize, file)
//            if numread == 0 { break }
//            var i = 0; while i < numread {
//                let _ = buff.load(fromByteOffset: i, as: UInt8.self)
//                i += 1
//            }
//        }
//    }
//    print("data fopen:", t)
//
//    // 9105 ticks
//    t = measureTicks(epochs: epochs) {
//        var iter = FileDataIterator(filePath: fileUrl.path())!
//        while let _ = iter.next() { }
//        iter.close()
//    }
//    print("data fopen iter:", t)

    
//    let n = 1000
//
//    t = measureTicks(epochs: epochs) {
//        var a = [Int]()
//        var i = 0; while i < n {
//            a.append(i)
//            i += 1
//        }
//    }
//    print("[Int]", t)
//
//    t = measureTicks(epochs: epochs) {
//        var a = [Int]()
//        a.reserveCapacity(1000)
//        var i = 0; while i < n {
//            a.append(i)
//            i += 1
//        }
//    }
//    print("[Int] reserve:", t)
//
//    t = measureTicks(epochs: epochs) {
//        var a = ContiguousArray<Int>()
//        var i = 0; while i < n {
//            a.append(i)
//            i += 1
//        }
//    }
//    print("ContiguousArray:", t)
//
//    t = measureTicks(epochs: epochs) {
//        var a = [Int].init(repeating: 0, count: 1000)
//        var i = 0; while i < n {
//            a[i] = i
//            i += 1
//        }
//    }
//    print("[Int].repeating:", t)
    
    // while vs forEach
    let n = 1000
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
