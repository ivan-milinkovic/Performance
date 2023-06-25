import Foundation

final class JsonParserBuffers {
    
    var log = false
    
    func parse(filePath: String) -> Any {

        let tokenizer = JsonTokenizer()
        let tokens = tokenizer.tokenize(filePath)
//        if log { print("Step 1 Tokens:", tokens.map(\.value).joined(separator: " ")) }

        let ltokens = LiteralParser.parse(tokens)
//        if log { print("Step 2 Values:", ltokens.map(\.description).joined(separator: " ")) }

        let collectionParser = CollectionParser()
        let result = collectionParser.parse(ltokens)
//        if log { print("Step 3 Semantic:", result) }
        
        return result
    }
}

private struct Token {
    let value: Buffer<CUChar>
    let isString: Bool
    init(value: Buffer<CUChar>, isString: Bool = false) {
        self.value = value
        self.isString = isString
    }
}

extension Token: CustomStringConvertible {
    var description: String {
        let vals = value.array.map { Unicode.Scalar(UInt32($0)) }
        return "\(vals) isstr: \(isString)"
    }
}

private final class JsonTokenizer {
    
    var tokens = [Token]()
    var currentToken = Buffer<CUChar>(placeholder: 0)
    var isInsideString = false // don't tokenize special chars inside a string, keep whitespaces, check for escapes
    var isEscape = false
    
    init() {
        reset()
    }
    
    private func reset() {
        tokens = [Token]()
        resetCurrentToken()
        isInsideString = false
        isEscape = false
    }
    
    private func resetCurrentToken() {
        currentToken = Buffer<CUChar>(placeholder: 0)
        isInsideString = false
    }
    
    func tokenize(_ filePath: String) -> [Token] {
        
        let file = fopen(filePath, "r")!
        defer { fclose(file) }
        let buffSize = 1_000_000
        let buff = UnsafeMutableRawPointer.allocate(byteCount: buffSize, alignment: 1)
        defer { buff.deallocate() }
        
//        var dataIter = FileDataIterator(filePath: filePath)!
//        while let char = dataIter.next() {

        while true {
            let numread = fread(buff, 1, buffSize, file)
            if numread == 0 {
                break
            }
            var i = 0; while i < numread { defer { i += 1 }
                let char = buff.load(fromByteOffset: i, as: UInt8.self)
                
                if isInsideString {
                    if char == TokenChar.stringEscape {
                        isEscape = true
                        continue // take next
                    }
                    if char == TokenChar.stringDelimiter {
                        if isEscape {
                            isEscape = false
                            currentToken.append(char)
                            continue
                        }
                        finalizeCurrentToken()
                        continue
                    }
                    currentToken.append(char)
                    continue
                }
                
                if TokenChar.isWhitespace(char) {
                    continue
                }
                
                if char == TokenChar.stringDelimiter {
                    isInsideString = true
                    continue
                }
                
                if TokenChar.isDelimiter(char) {
                    finalizeCurrentToken()
                    // store the new delimiter token
                    currentToken.append(char)
                    finalizeCurrentToken()
                    continue
                }
                
                currentToken.append(char)
            }
        }
        
        finalizeCurrentToken()
        let result = tokens
        reset()
        return result
    }
    
    private func finalizeCurrentToken() {
        if !currentToken.isEmpty {
            tokens.append(Token(value: currentToken, isString: isInsideString))
        }
        resetCurrentToken()
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
    
    static let null = "null"
    static let `true` = "true"
    static let `false` = "false"
    
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

    static func parse(_ tokens: [Token]) -> [LiteralToken] {
        
        var itokens = [LiteralToken]()
        for token in tokens {
            
            if token.value.count == 1 {
                let char = token.value[0]
                switch char {
                case TokenChar.mapOpen:     itokens.append(.mapOpen)
                case TokenChar.mapClose:    itokens.append(.mapClose)
                case TokenChar.arrayOpen:   itokens.append(.arrayOpen)
                case TokenChar.arrayClose:  itokens.append(.arrayClose)
                case TokenChar.keyValueDelimiter:   itokens.append(.keyValueDelimiter)
                case TokenChar.elementDelimiter:    itokens.append(.elementDelimiter)
                default: fatalError("Uknown character: \(char)")
                }
                continue
            }
            
            if token.isString {
                let str = String(cString: Array(token.value.array) + CollectionOfOne(0))
                itokens.append(.literalValue(.string(str)))
                continue
            }
            
            let chars = token.value
            
            if chars.count == 4+1 { // +1 for 0 terminated
                
                // check true
                if    (chars[0] == 84 /*T*/ || chars[0] == 116) /*t*/
                   && (chars[1] == 82 /*R*/ || chars[1] == 114) /*r*/
                   && (chars[2] == 85 /*U*/ || chars[2] == 117) /*u*/
                   && (chars[3] == 69 /*E*/ || chars[3] == 101) /*e*/
                {
                    itokens.append(.literalValue(.bool(true)))
                    continue
                }
                
                // check null
                if    (chars[0] == 78 /*N*/ || chars[0] == 110) /*n*/
                   && (chars[1] == 85 /*U*/ || chars[1] == 117) /*u*/
                   && (chars[2] == 76 /*L*/ || chars[2] == 108) /*l*/
                   && (chars[3] == 76 /*L*/ || chars[3] == 108) /*l*/
                {
                    itokens.append(.literalValue(.null(NSNull())))
                    continue
                }
                
            }
            
            // check false
            if chars.count == 5+1 { // +1 for 0 terminated
                if    (chars[0] == 70 /*F*/ || chars[0] == 102) /*f*/
                   && (chars[1] == 65 /*A*/ || chars[1] == 97) /*a*/
                   && (chars[2] == 76 /*L*/ || chars[2] == 108) /*l*/
                   && (chars[3] == 83 /*S*/ || chars[3] == 105) /*s*/
                   && (chars[4] == 69 /*E*/ || chars[4] == 101) /*e*/
                {
                    itokens.append(.literalValue(.bool(false)))
                    continue
                }
            }
            
            let str = String(cString: Array(token.value.array) + CollectionOfOne(0))
            if let number = Double(str) {
                itokens.append(.literalValue(.number(number)))
                continue
            }
            
            fatalError("Unexpected value: \(token.value)")
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
    
    func consume(_ val: LiteralValue) {
        if key == nil {
            guard case .string(let str) = val else {
                fatalError("Invalid json, expected a key (a string), but got a \(val.value)")
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
}

