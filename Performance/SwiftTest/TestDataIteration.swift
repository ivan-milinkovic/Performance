import Foundation

func testDataIteration() {
    
    /*
     data copy ptr: 996
     data iter: 11413
     nsdata: 384310
     nsdata bytes: 76536
     data forEach: 14181
     data ptr: 7691
     data cont ptr: 1
     data fopen: 619
     data fopen iter: 1199
     BufferedDataReader: 5265
     */
    
    let jsonFile = "coords_1_000.json"
//    let jsonFile = "coords_10_000.json"
//    let jsonFile = "coords_1_000_000.json"
    let fileUrl = dataDirUrl.appending(path: jsonFile, directoryHint: URL.DirectoryHint.notDirectory)

    do {
        let data = try! Data(contentsOf: fileUrl)
        Profiler.reset()
        Profiler.start(0)
        let ptr = UnsafeMutableRawBufferPointer.allocate(byteCount: data.count, alignment: 1)
        data.copyBytes(to: ptr)
        var i = 0; while i < data.count { defer { i += 1 }
            let _ = ptr[i]
        }
        Profiler.end(0)
        print("data copy ptr:", Profiler.ticks(0))
    }
    
    do {
        let data = try! Data(contentsOf: fileUrl)
        Profiler.reset()
        Profiler.start(0)
        var iter = data.makeIterator()
        while let b = iter.next() {
            let _ = b
        }
        Profiler.end(0)
        print("data iter:", Profiler.ticks(0))
    }

    do {
        let data = NSData(contentsOf: fileUrl)!
        Profiler.reset()
        Profiler.start(0)
        var i = 0; while i < data.count { defer { i += 1 }
            let _ = data[i]
        }
        Profiler.end(0)
        print("nsdata:", Profiler.ticks(0))
    }

    do {
        let data = NSData(contentsOf: fileUrl)!
        Profiler.reset()
        Profiler.start(0)
        var i = 0; while i < data.count { defer { i += 1 }
            let _ = (data.bytes + i).load(as: UInt8.self)
        }
        Profiler.end(0)
        print("nsdata bytes:", Profiler.ticks(0))
    }


    do {
        let data = try! Data(contentsOf: fileUrl)
        Profiler.reset()
        Profiler.start(0)
        data.forEach { b in
            let _ = b
        }
        Profiler.end(0)
        print("data forEach:", Profiler.ticks(0))
    }

    do {
        let data = try! Data(contentsOf: fileUrl)
        Profiler.reset()
        Profiler.start(0)
        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            var i = 0; while i < data.count { defer { i += 1 }
                let _ = data[i]
            }
        }
        Profiler.end(0)
        print("data ptr:", Profiler.ticks(0))
    }

    do {
        let data = try! Data(contentsOf: fileUrl)
        Profiler.reset()
        Profiler.start(0)
        data.withContiguousStorageIfAvailable { (ptr: UnsafeBufferPointer<UInt8>) in
            var i = 0; while i < data.count { defer { i += 1 }
                let _ = data[i]
            }
        }
        Profiler.end(0)
        print("data cont ptr:", Profiler.ticks(0))
    }


    // buffer of:
    // 5 equals swifts Data performance
    // 1MB (1_000_000) ~ 800 ticks
    // 2MB (2_000_000) ~ 2000 ticks allocation overhead
    do {
        let file = fopen(fileUrl.path(), "r")!
        defer { fclose(file) }
        Profiler.reset()
        Profiler.start(0)
        let buffSize = 1_000_000
        let buff = UnsafeMutableRawPointer.allocate(byteCount: buffSize, alignment: 1)
        defer { buff.deallocate() }

        while true {
            let numread = fread(buff, 1, buffSize, file)
            if numread == 0 { break }
            var i = 0; while i < numread {
                let _ = buff.load(fromByteOffset: i, as: UInt8.self)
                i += 1
            }
        }
        Profiler.end(0)
        print("data fopen:", Profiler.ticks(0))
    }
    
    do {
        Profiler.reset()
        Profiler.start(0)
        var iter = FileDataIterator(filePath: fileUrl.path())!
        while let _ = iter.next() { }
        iter.close()
        Profiler.end(0)
        print("data fopen iter:", Profiler.ticks(0))
    }
    
    do {
//        let data = Data([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])
        let data = try! Data(contentsOf: fileUrl)
        Profiler.reset()
        Profiler.start(0)
        var dataReader = BufferedDataReader(data: data, buffSize: 2000)
        while let byte = dataReader.next() {
            let _ = byte
        }
        Profiler.end(0)
        print("BufferedDataReader:", Profiler.ticks(0))
    }
}
