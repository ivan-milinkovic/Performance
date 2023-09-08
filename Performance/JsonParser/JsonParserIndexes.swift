import Foundation

final class JsonParserIndexes {

    func parse(data: Data) -> Any {
        
        let tokenizer = JsonTokenizer()
        let tokens = tokenizer.tokenize(data)
        
        let ltokens = LiteralParser.parse(tokens, sourceData: data)
        
        let collectionParser = CollectionParser()
        let result = collectionParser.parse(ltokens)

        return result
    }
    
    func parse(jsonString str: String) -> Any {
        parse(data: str.data(using: .utf8)!)
    }
}

let reservedCapacity = 5

private struct Token {
    var index : Int
    var length : Int
    var isString: Bool
    
    init(index : Int, length : Int, isString: Bool = false) {
        self.index = index
        self.length = length
        self.isString = isString
    }
}

extension Token {
    func desc(_ data: Data) -> String {
        let bytes = data[index..<index + length]
        let str = String(data: bytes, encoding: .utf8)!
        return "<\(str)>\(isString ? "s" : "")"
    }
}

private final class JsonTokenizer {
    
    var tokens = [Token]()
    var currentToken = Token(index: 0, length: 0)
    var isInsideString = false // checks for escapes and ignores json chars so not to close a string early
    var isEscape = false
    
    init() {
        reset()
    }
    
    private func reset() {
        tokens = [Token]()
        tokens.reserveCapacity(reservedCapacity)
        resetCurrentToken(nextDataIndex: 0)
        isInsideString = false
        isEscape = false
    }
    
    private func resetCurrentToken(nextDataIndex: Int) {
        currentToken = Token(index: nextDataIndex, length: 0)
        isInsideString = false
    }
    
    func tokenize(_ data: Data) -> [Token] {
        
        let ptr = UnsafeMutableRawBufferPointer.allocate(byteCount: data.count, alignment: 1)
        defer { ptr.deallocate() }
        data.copyBytes(to: ptr)
        
        var i = 0; while i < data.count { defer { i += 1 }
            let char = ptr[i]
            
            if isInsideString {
                if char == TokenChar.stringEscape {
                    isEscape = true
                    currentToken.length += 1
                    continue // take next
                }
                if char == TokenChar.stringDelimiter {
                    if isEscape {
                        isEscape = false
                        currentToken.length += 1
                        continue
                    }
                    currentToken.length += 1
                    finalizeCurrentToken(i)
                    continue
                }
                currentToken.length += 1
                continue
            }
            
            if TokenChar.isWhitespace(char) {
                if currentToken.length == 0 {
                    currentToken.index += 1
                } else {
                    finalizeCurrentToken(i)
                }
                continue
            }
            
            if char == TokenChar.stringDelimiter {
                isInsideString = true
                currentToken.length += 1
                continue
            }
            
            if TokenChar.isDelimiter(char) {
                finalizeCurrentToken(i)
                currentToken.index = i // reset the i + 1 done in finalize
                currentToken.length = 1 // store the new delimiter token
                finalizeCurrentToken(i)
                continue
            }
            
            currentToken.length += 1
        }
        
        finalizeCurrentToken(i)
        let result = tokens
        reset() // reset parser to be re-used
        return result
    }
    
    private func finalizeCurrentToken(_ i: Int) {
        if currentToken.length > 0 {
            currentToken.isString = isInsideString
            tokens.append(currentToken)
        }
        resetCurrentToken(nextDataIndex: i + 1)
    }
}

private typealias CUChar = CUnsignedChar

private struct TokenChar {
    
//    static let delimiters : [Character] = [mapOpen, mapClose, arrayOpen, arrayClose, keyValueDelimiter, elementDelimiter]
    
    static let space = CUChar(32) // " "
    static let newline = CUChar(10) // "\n" line feed
    static let carriage = CUChar(13) // "\r"
    static let tab = CUChar(9) // "\t"
    
    static let stringDelimiter = CUChar(34) // "\""
    static let stringEscape = CUChar(92) // "\\"
    
    static let mapOpen = CUChar(123) // "{"
    static let mapClose = CUChar(125) // "}"
    static let arrayOpen = CUChar(91) // "["
    static let arrayClose = CUChar(93) // "]"
    static let keyValueDelimiter = CUChar(58) // ":"
    static let elementDelimiter = CUChar(44) // ","
    
    static func isWhitespace(_ char: CUChar) -> Bool {
        char == space || char == newline || char == carriage || char == tab
    }
    
    static func isDelimiter(_ char: CUChar) -> Bool {
        char == mapOpen || char == mapClose
        || char == arrayOpen || char == arrayClose
        || char == keyValueDelimiter || char == elementDelimiter
    }
}

private class LiteralParser {

    static func parse(_ tokens: [Token], sourceData data: Data) -> [LiteralToken] {
        
        var itokens = [LiteralToken]()
        itokens.reserveCapacity(reservedCapacity)
        
        for token in tokens {
            
            if token.length == 1 {
                let char = data[token.index]
                switch char {
                case TokenChar.mapOpen:     itokens.append(.mapOpen)
                case TokenChar.mapClose:    itokens.append(.mapClose)
                case TokenChar.arrayOpen:   itokens.append(.arrayOpen)
                case TokenChar.arrayClose:  itokens.append(.arrayClose)
                case TokenChar.keyValueDelimiter:   itokens.append(.keyValueDelimiter)
                case TokenChar.elementDelimiter:    itokens.append(.elementDelimiter)
                default:
                    if let number = tryMakeDouble(startIndex: token.index, length:token.length, data: data) {
                        itokens.append(.literalValue(.number(number)))
                        continue
                    } else {
                        fatalError("Unexpected char: \(char)")
                    }
                }
                continue
            }
            
            if token.isString {
                let tokenData = data[(token.index+1)..<(token.index + token.length - 1)] // +-1 to ignore opening closing quotes "
                let str = String(data: tokenData, encoding: .utf8)!
                itokens.append(.literalValue(.string(str)))
                continue
            }
            
            if token.length == 4 {
                
                // check true
                if    (data[token.index + 0] == 84 /*T*/ || data[token.index + 0] == 116) /*t*/
                   && (data[token.index + 1] == 82 /*R*/ || data[token.index + 1] == 114) /*r*/
                   && (data[token.index + 2] == 85 /*U*/ || data[token.index + 2] == 117) /*u*/
                   && (data[token.index + 3] == 69 /*E*/ || data[token.index + 3] == 101) /*e*/
                {
                    itokens.append(.literalValue(.bool(true)))
                    continue
                }
                
                // check null
                if    (data[token.index + 0] == 78 /*N*/ || data[token.index + 0] == 110) /*n*/
                   && (data[token.index + 1] == 85 /*U*/ || data[token.index + 1] == 117) /*u*/
                   && (data[token.index + 2] == 76 /*L*/ || data[token.index + 2] == 108) /*l*/
                   && (data[token.index + 3] == 76 /*L*/ || data[token.index + 3] == 108) /*l*/
                {
                    itokens.append(.literalValue(.null(NSNull())))
                    continue
                }
                
            }
            
            // check false
            if token.length == 5 {
                if    (data[token.index + 0] == 70 /*F*/ || data[token.index + 0] == 102) /*f*/
                   && (data[token.index + 1] == 65 /*A*/ || data[token.index + 1] ==  97) /*a*/
                   && (data[token.index + 2] == 76 /*L*/ || data[token.index + 2] == 108) /*l*/
                   && (data[token.index + 3] == 83 /*S*/ || data[token.index + 3] == 115) /*s*/
                   && (data[token.index + 4] == 69 /*E*/ || data[token.index + 4] == 101) /*e*/
                {
                    itokens.append(.literalValue(.bool(false)))
                    continue
                }
            }
            
            if let number = tryMakeDouble(startIndex: token.index, length:token.length, data: data) {
                itokens.append(.literalValue(.number(number)))
                continue
            }
            
            let str = String(data: data[token.index..<(token.index + token.length)], encoding: .utf8)!
            fatalError("Unexpected value: \(str)")
        }
        return itokens
    }
}

private enum LiteralToken {
    case mapOpen
    case mapClose
    
    case arrayOpen
    case arrayClose
    
    case keyValueDelimiter
    case elementDelimiter
    
    case literalValue(LiteralValue)
}

private enum LiteralValue {
    case string (String)
    case number (Double)
    case bool   (Bool)
    case null   (NSNull)
    
    var value: Any {
        switch self {
        case .string(let string): return string
        case .number(let double): return double
        case .bool(let bool):     return bool
        case .null(let nsull):    return nsull
        }
    }
}

extension LiteralValue: CustomStringConvertible {
    var description: String {
        switch self {
        case .string(let string): return string
        case .number(let double): return "\(double)"
        case .bool(let bool):     return "\(bool)"
        case .null(_):            return "null"
        }
    }
}

extension LiteralToken: CustomStringConvertible {
    var description: String {
        switch self {
        case .mapOpen:           return String(TokenChar.mapOpen)
        case .mapClose:          return String(TokenChar.mapClose)
        case .arrayOpen:         return String(TokenChar.arrayOpen)
        case .arrayClose:        return String(TokenChar.arrayClose)
        case .keyValueDelimiter: return String(TokenChar.keyValueDelimiter)
        case .elementDelimiter:  return String(TokenChar.elementDelimiter)
        case .literalValue(let val): return val.description
        }
    }
}

private class CollectionParser {
    
    private var stack = Stack<JsonCollection>()
    private var result: Any = NSNull()
    
    init() {
        reset()
    }
    
    private func reset() {
        stack = Stack<JsonCollection>()
        stack.reserveCapacity(reservedCapacity)
        result = NSNull()
    }
    
    func parse(_ itokens: [LiteralToken]) -> Any {
        
        if itokens.count == 0 { return NSNull() }
        
        if itokens.count == 1, case .literalValue(let literalValue) = itokens.first! {
            return literalValue.value
        }
        
        for itoken in itokens {
            switch itoken {
            case .mapOpen:
                stack.push(.map(JsonMap()))
                
            case .mapClose:
                popStack()
                
            case .arrayOpen:
                stack.push(.array(JsonArray()))
                
            case .arrayClose:
                popStack()
                
            case .keyValueDelimiter:
                guard let current = stack.top(),
                      case .map(let map) = current,
                      map.key != nil // since we're at key-value delimiter, the key must be already set
                else {
                    fatalError("Invalid json, got the key-value separator '\(TokenChar.keyValueDelimiter)' without a key being set previously")
                }
            
            case .elementDelimiter:
                guard let current = stack.top() else {
                    fatalError("Invalid json, no collection")
                }
                if case .map(let map) = current, map.isComplete == false {
                    fatalError("Invalid json, got the element delimiter '\(TokenChar.elementDelimiter)',"
                               + "while the map is incomplete: key: \(String(describing: map.key))")
                }
                
            case .literalValue(let literalValue):
                guard let current = stack.top() else {
                    fatalError("Invalid json, no collection, but got: \(literalValue.value)")
                }
                current.merge(literalValue.value)
            }
        }
        
        let resultCopy = result
        reset()
        return resultCopy
    }
    
    private func popStack() {
        let current = stack.pop()
        if let parent = stack.top() {
            parent.merge(current.value)
        } else {
            if case .map(let map) = current, map.isComplete == false {
                fatalError("Invalid json, a map is incomplete")
            } else {
                result = current.value
            }
        }
    }
}

private enum JsonCollection {
    
    case map(JsonMap)
    case array(JsonArray)
    
    var value: Any {
        switch self {
        case .map(let jsonMap): return jsonMap.value
        case .array(let jsonArray): return jsonArray.value
        }
    }
    
    func merge(_ val: Any) {
        switch self {
        case .map(let map):
            map.consume(val)
            
        case .array(let jsonArray):
            jsonArray.value.append(val)
        }
    }
}

private class JsonMap {
    var value = [String: Any]()
    var key: String?
    
    init() {
        value.reserveCapacity(reservedCapacity)
    }
    
    var isComplete: Bool {
        key == nil
    }
    
    func consume(_ val: Any) {
        if key == nil {
            guard let str = val as? String else {
                fatalError("Invalid json, expected a key (a string), but got a \(type(of: val))")
            }
            key = str
        }
        else {
            value[key!] = val
            key = nil
        }
    }
}

private class JsonArray {
    var value = [Any]()
    init() {
        value.reserveCapacity(reservedCapacity)
    }
}

extension UInt8 {
    var ascii: String {
        String(cString: [self, 0])
    }
}
