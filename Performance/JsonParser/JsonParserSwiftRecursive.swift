import Foundation

final class JsonParserSwiftRecursive {
    
    var error: String?
    
    func parse(data: Data) -> Any? {
        var index = 0
        let len = data.count
        var res : Any? = nil
        
        data.withUnsafeBytes { bytes -> Void in
            res = root(bytes: bytes, index: &index, len: len)
            return
        }
        
        if (error != nil) {
            return nil
        }
        
        return res
    }
    
    private func root(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) -> Any? {
        
        skipWhitespace(bytes: bytes, index: &index, len: len)
        if isDone(index, len) { return nil }
        
        var res : Any? = nil
        let char = bytes[index]
        switch char {
        case AsciiChars.n:
            res = parseNull(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.t:
            res = parseTrue(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.f:
            res = parseFalse(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.stringDelimiter:
            res = parseString(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.mapOpen:
            res = parseMap(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.arrayOpen:
            res = parseArray(bytes: bytes, index: &index, len: len)
            
        default:
            if AsciiChars.isNumeric(char: char) {
                res = parseNumber(bytes: bytes, index: &index, len: len)
                break
            }
            
            error = "Unexpected character \(char)"
            return nil
        }
        
        if (error != nil) {
            return nil
        }
        
        skipWhitespace(bytes: bytes, index: &index, len: len)
        if isDone(index, len) {
            error = "Cannot have elements after root element"
            return nil
        }
        
        return res
    }
    
    private func innerParse(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) -> Any? {
        
        skipWhitespace(bytes: bytes, index: &index, len: len)
        if isDone(index, len) {
            error = "Element is incomplete"
            return nil
        }
        
        var res : Any? = nil
        let char = bytes[index]
        switch char {
        case AsciiChars.n:
            res = parseNull(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.t:
            res = parseTrue(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.f:
            res = parseFalse(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.stringDelimiter:
            res = parseString(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.mapOpen:
            res = parseMap(bytes: bytes, index: &index, len: len)
            
        case AsciiChars.arrayOpen:
            res = parseArray(bytes: bytes, index: &index, len: len)
            
        default:
            if AsciiChars.isNumeric(char: char) {
                res = parseNumber(bytes: bytes, index: &index, len: len)
                break
            }
            
            error = "innerParse: unexpected character \(char)"
            return nil
        }
        
        return res
    }
    
    private func skipWhitespace(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) {
        while index < len {
            let char = bytes[index]
            if !AsciiChars.isWhitespace(char) {
                break
            }
            index += 1;
        }
    }
    
    private func isDone(_ index: Int, _ len: Int) -> Bool {
        index > len
    }
    
    private func parseNull(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) -> NSNull? {
        if (len - index) < 4 {
            error = "parseNull: invalid length"
            return nil
        }
        if (bytes[index + 0] == 110) /*n*/
        && (bytes[index + 1] == 117) /*u*/
        && (bytes[index + 2] == 108) /*l*/
        && (bytes[index + 3] == 108) /*l*/
        {
            return NSNull()
        }
        return nil
    }
    
    private func parseTrue(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) -> Bool? {
        if (len - index) < 4 {
            error = "parseTrue: invalid length"
            return nil
        }
        if (bytes[index + 0] == 116) /*t*/
        && (bytes[index + 1] == 114) /*r*/
        && (bytes[index + 2] == 117) /*u*/
        && (bytes[index + 3] == 101) /*e*/
        {
            return true
        }
        return nil
    }
    
    private func parseFalse(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) -> Bool? {
        if (len - index) < 4 {
            error = "parseTrue: invalid length"
            return nil
        }
        if (bytes[index + 0] == 102) /*f*/
        && (bytes[index + 1] ==  97) /*a*/
        && (bytes[index + 2] == 108) /*l*/
        && (bytes[index + 3] == 115) /*s*/
        && (bytes[index + 4] == 101) /*e*/
        {
            return false
        }
        return nil
    }
    
    private func parseString(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) -> String? {
        index += 1
        if isDone(index, len) {
            error = "String malformed"
            return nil
        }
        
        var isEscaping = false
        let iStart = index
        while (index < len) {
            let c = bytes[index]
            if c == AsciiChars.stringEscape {
                isEscaping = true
            }
            // todo: validate escaped char
            if c == AsciiChars.stringDelimiter && !isEscaping {
                break
            }
            index += 1
        }
        
        let strLen = index - iStart
        let subData = Data.init(bytes: bytes.baseAddress! + iStart, count: strLen)
        let str = String.init(data: subData, encoding: .utf8)
        index += 1
        return str
    }
    
    private func parseNumber(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) -> Double? {
        let iStart = index
        var numLen = 0
        while index < len {
            let c = bytes[index]
            if !AsciiChars.isNumeric(char: c) {
                break
            }
            index += 1
            numLen += 1
        }
        
        if numLen == 0 {
            return nil
        }
        
        return tryMakeDouble3(startIndex: iStart, length: numLen, bytes: bytes)
    }
    
    private func parseMap(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) -> [String: Any]? {
        
        index += 1
        skipWhitespace(bytes: bytes, index: &index, len: len)
        if isDone(index, len) {
            error = "Map is incomplete"
            return nil
        }
        
        var map = [String: Any]()
        
        let c = bytes[index]
        if c == AsciiChars.mapClose {
            index += 1
            return map
        }
        
        skipWhitespace(bytes: bytes, index: &index, len: len)
        if isDone(index, len) {
            error = "Map is incomplete"
            return nil
        }
        
        var spin = true
        while spin {
            skipWhitespace(bytes: bytes, index: &index, len: len)
            if isDone(index, len) {
                error = "Map is incomplete"
                return nil
            }
            
            let key = parseString(bytes: bytes, index: &index, len: len)
            if (error != nil) { return nil }
            
            // search for key value delimiter ":"
            skipWhitespace(bytes: bytes, index: &index, len: len)
            if isDone(index, len) {
                error = "Map is incomplete"
                return nil
            }
            
            var c = bytes[index]
            if c != AsciiChars.keyValueDelimiter {
                error = "Map expects a \":\" delimiter after the key"
                return nil
            }
            index += 1
            
            let value = innerParse(bytes: bytes, index: &index, len: len)
            if (error != nil) { return nil }
            if value == nil {
                error = "Map value is missing"
                return nil
            }
            map[key!] = value!
            
            
            // continue or not
            skipWhitespace(bytes: bytes, index: &index, len: len)
            if isDone(index, len) {
                error = "Map is incomplete"
                return nil
            }
            c = bytes[index]
            switch c {
            case AsciiChars.elementDelimiter:
                index += 1
                continue // parse more key-value pairs
                
            case AsciiChars.mapClose:
                spin = false
                break
                
            default:
                error = "Map expects an element delimiter \",\" or a closing curly brace \"}\""
                return nil
            }
            
            index += 1
        }
        
        return map
    }
    
    private func parseArray(bytes: UnsafeRawBufferPointer, index: inout Int, len: Int) -> [Any]? {
        
        index += 1
        
        skipWhitespace(bytes: bytes, index: &index, len: len)
        if isDone(index, len) {
            error = "Array is incomplete"
            return nil
        }
        
        var array = [Any]()
        
        var c = bytes[index]
        if c == AsciiChars.arrayClose {
            index += 1
            return array
        }
        
        spin: while true {
            skipWhitespace(bytes: bytes, index: &index, len: len)
            if isDone(index, len) {
                error = "Array is incomplete"
                return nil
            }
            
            let value = innerParse(bytes: bytes, index: &index, len: len)
            if (value == nil) {
                error = "Array value is missing"
                return nil
            }
            
            array.append(value!)
            
            // continue or not
            skipWhitespace(bytes: bytes, index: &index, len: len)
            if isDone(index, len) {
                error = "Array is incomplete"
                return nil
            }
            
            c = bytes[index]
            switch c {
            case AsciiChars.elementDelimiter:
                index += 1
                continue // parse more values
                
            case AsciiChars.arrayClose:
                index += 1
                break spin
                
            default:
                error = "Array expects an element delimiter \",\" or a closing square bracket \"]\""
                return nil
            }
            
        }
        
        return array
    }
    
    private func pc(_ char: UInt8) -> Character {
        Character(Unicode.Scalar(char))
    }
}

private struct AsciiChars {
    
    static let space = UInt8(32) // " "
    static let newline = UInt8(10) // "\n" line feed
    static let carriage = UInt8(13) // "\r"
    static let tab = UInt8(9) // "\t"
    
    static let stringDelimiter = UInt8(34) // "\""
    static let stringEscape = UInt8(92) // "\\"
    
    static let mapOpen = UInt8(123) // "{"
    static let mapClose = UInt8(125) // "}"
    static let arrayOpen = UInt8(91) // "["
    static let arrayClose = UInt8(93) // "]"
    static let keyValueDelimiter = UInt8(58) // ":"
    static let elementDelimiter = UInt8(44) // ","
    
    static let n = UInt8(110) // "n"
    static let t = UInt8(116) // "t"
    static let f = UInt8(102) // "f"
    
    static let plus = UInt8(43) // "+"
    static let minus = UInt8(45) // "-"
    static let dot = UInt8(46) // "-"
    static let _0 = UInt8(48) // "0"
    static let _1 = UInt8(49) // "1"
    static let _2 = UInt8(50) // "2"
    static let _3 = UInt8(51) // "3"
    static let _4 = UInt8(52) // "4"
    static let _5 = UInt8(53) // "5"
    static let _6 = UInt8(54) // "6"
    static let _7 = UInt8(55) // "7"
    static let _8 = UInt8(56) // "8"
    static let _9 = UInt8(57) // "9"
    
    static func isNumeric(char c: UInt8) -> Bool {
        c == plus || c == minus || c == dot
       || c == _0 || c == _1 || c == _2 || c == _3 || c == _4
       || c == _5 || c == _6 || c == _7 || c == _8 || c == _9;
    }
    
    static func isWhitespace(_ char: UInt8) -> Bool {
        char == space || char == newline || char == carriage || char == tab
    }
}
