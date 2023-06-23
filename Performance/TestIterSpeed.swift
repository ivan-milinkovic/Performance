//
//  TestIterSpeed.swift
//  Performance
//
//  Created by Ivan Milinkovic on 23.6.23..
//

import Foundation

func testIterSpeed() {
    let N = 1000
    print(measureTicks(epochs: N, task: forIn(_:_:)))
    print(measureTicks(epochs: N, task: strIter(_:_:)))
    print(measureTicks(epochs: N, task: makingCharArray(_:_:)))
    print(measureTicks(epochs: N, task: dataIter(_:_:)))
}

private func measureTicks(epochs: Int, task: (Data, String) -> Void) -> Int {
    let (data, str) = loadFile()
    var i = 0
    var t0 : UInt64 = 0
    var sum : UInt64 = 0
    while i < epochs {
        t0 = mach_absolute_time()
        task(data, str)
        sum += mach_absolute_time() - t0
        i += 1
    }
    let avg = Double(sum) / Double(i-1)
    return Int(avg)
}

private func loadFile() -> (Data, String) {
    let jsonFile = "testJson.json"
    let inputFileUrl = dataDirUrl.appending(path: jsonFile, directoryHint: URL.DirectoryHint.notDirectory)
    let data = try! Data(contentsOf: inputFileUrl)
    var jsonString = String.init(data: data, encoding: .utf8)!
    jsonString.makeContiguousUTF8()
    return (data, jsonString)
}

private func forIn(_ data: Data, _ str: String) {
    for c in str {
        let _ = c
    }
}

private func strIter(_ data: Data, _ str: String) {
    var siter = str.makeIterator()
    while let c = siter.next() {
        let _ = c
    }
}

private func makingCharArray(_ data: Data, _ str: String) {
    let a = Array<Character>(str)
    var i = 0
    while i < a.count {
        let _ = a[i]
        i += 1
    }
}

private func charArray(_ data: Data, _ a: Array<Character>) {
    var i = 0
    while i < a.count {
        let _ = a[i]
        i += 1
    }
}

private func dataIter(_ data: Data, _ str: String) {
    var diter = data.makeIterator()
    while let c = diter.next() {
        let _ = c
    }
}
