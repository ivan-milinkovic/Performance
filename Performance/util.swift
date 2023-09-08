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

extension TimeInterval {
    var string: String {
        timeString(self)
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
    if floor(ns) != 0 {
        return String(format: "%.2fns", ns)
    }
    
    let ps = ns * 1_000
    return String(format: "%.2fps", ps)
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
    
    func reserveCapacity(_ cap: Int) {
        contents.reserveCapacity(cap)
    }
    
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
    
    // Used to modify values (as they are copied when taken out)
    func replaceTop(_ val: T) {
        contents[contents.count - 1] = val
    }
}

struct FileDataIterator {
    
    private let file: UnsafeMutablePointer<FILE>
    private let buffSize = 1_000_000
    private let buff : UnsafeMutableRawPointer
    private var numread = -1
    private var index = 0
    
    init?(filePath: String) {
        guard let f = fopen(filePath, "r") else { return nil }
        file = f
        buff = UnsafeMutableRawPointer.allocate(byteCount: buffSize, alignment: 1)
        guard readBuffer() else { return nil }
    }
    
    private mutating func readBuffer() -> Bool {
        index = 0
        numread = fread(buff, 1, buffSize, file)
        if numread == 0 { return false }
        return true
    }
    
    mutating func next() -> UInt8? {
        if index == numread {
            guard readBuffer() else { return nil }
        }
        if numread == 0 { return nil } // all read, no more bytes
        
        let byte = buff.load(fromByteOffset: index, as: UInt8.self)
        index += 1
        return byte
    }
    
    func close() {
        fclose(file)
        buff.deallocate()
    }
}

struct ArrayBuffer<T> {
    
    private var buff : [T]
    private var i = 0
    private let placeholder: T
    private var capacity = 10
    
    init(placeholder: T) {
        self.placeholder = placeholder
        buff = [T].init(repeating: placeholder, count: capacity)
    }
    
    mutating func append(_ v: T) {
        if i == capacity { increaseCapacity() }
        buff[i] = v
        i += 1
    }
    
    private mutating func increaseCapacity() {
        capacity += capacity
        var newbuff = [T].init(repeating: placeholder, count: capacity)
        var j = 0; while j < buff.count { defer { j += 1}
            newbuff[j] = buff[j]
        }
        buff = newbuff
    }
    
    var isEmpty: Bool {
        i == 0
    }
    
    var count: Int { i }
    
    subscript(index: Int) -> T {
        precondition(0 <= index && index < i)
        return buff[index]
    }
    
    var array: ArraySlice<T> {
        buff.prefix(i)
    }
}

struct PtrBuffer<T> {
    
    private var buff : UnsafeMutablePointer<T>
    private var i = 0
    private let initialCapacity = 10
    private var currentCapacity : Int
    
    init() {
        currentCapacity = initialCapacity
        buff = UnsafeMutablePointer<T>.allocate(capacity: initialCapacity)
        i = 0
    }
    
    mutating func append(_ v: T) {
        if i == currentCapacity { increaseCapacity() }
        buff[i] = v
        i += 1
    }
    
    private mutating func increaseCapacity() {
        let newCapacity = currentCapacity + initialCapacity
        let newbuff = UnsafeMutablePointer<T>.allocate(capacity: newCapacity)
        var j = 0; while j < currentCapacity { defer { j += 1}
            newbuff[j] = buff[j]
        }
        buff.deallocate()
        buff = newbuff
        currentCapacity = newCapacity
    }
    
    func free() {
        buff.deallocate()
    }
    
    var isEmpty: Bool {
        i == 0
    }
    
    var count: Int { i }
    
    subscript(index: Int) -> T {
        precondition(0 <= index && index < i)
        return buff[index]
    }
    
    func array(placeholder: T) -> [T] {
        var a = Array<T>(repeating: placeholder, count: i)
        var j = 0; while j < i { defer { j += 1}
            a[j] = buff[j]
        }
        return a
    }

}

struct BufferedDataReader {
    let data: Data
    private let buffSize : Int
    private var buffer : [UInt8]
    private var i_data = 0 // whole data index counter
    private var i_buff = 0 // current buffer index
    
    init(data: Data, buffSize: Int) {
        self.data = data
        self.buffSize = buffSize
        buffer = [UInt8](repeating: 0, count: buffSize)
        loadBuffer()
    }
    
    private mutating func loadBuffer() {
        if i_data >= data.count { return }
        let upperBound = min(data.count, i_data + buffSize)
        let range = i_data..<upperBound
        data.copyBytes(to: &buffer, from: range)
        i_buff = 0
    }
    
    mutating func next() -> UInt8? {
        if i_data >= data.count { return nil }
        if i_buff >= buffSize { loadBuffer() }
        defer {
            i_data += 1
            i_buff += 1
        }
        return buffer[i_buff]
    }
}
