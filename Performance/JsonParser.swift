import Foundation

func testJsonParser() {
    let jsonFile = "testJson.json"
    let inputFileUrl = dataDirUrl.appending(path: jsonFile, directoryHint: URL.DirectoryHint.notDirectory)
    let jsonString = try! String.init(contentsOf: inputFileUrl)
    print("input:")
    print(jsonString)
    let jsonParser = JsonParser()
    let jsonStructure = jsonParser.parse(jsonString: jsonString)
    print()
    print("output:")
    print(jsonStructure)
    print()
}

final class JsonParser {
    
    func parse(jsonString str: String) -> Any {
        
        let tokenizer = JsonTokenizer()
        let tokens = tokenizer.tokenize(jsonString: str)
        print("Step 1 Tokens:", tokens.map(\.value).joined(separator: " "))
        
        let ltokens = LiteralParser.parse(tokens)
        print("Step 2 Values:", ltokens.map(\.description).joined(separator: " "))
        
        let collectionParser = CollectionParser()
        let result = collectionParser.parse(ltokens)
        print("Step 3 Semantic:", result)
        
        return result
    }
}

private struct Token {
    let value: String
    let isString: Bool
    init(value: String, isString: Bool = false) {
        self.value = value
        self.isString = isString
    }
}

private final class JsonTokenizer {
    
    var tokens = [Token]()
    var currentToken = ""
    var isInsideString = false // don't tokenize special chars inside a string, keep whitespaces, check for escapes
    var isEscape = false
    
    init() {
        reset()
    }
    
    private func reset() {
        tokens = [Token]()
        currentToken = ""
        isInsideString = false
        isEscape = false
    }
    
    func tokenize(jsonString str: String) -> [Token] {
        
        var strIter = str.makeIterator()
        while let char = strIter.next() {
            
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
            
            if TokenChar.delimiters.contains(char) {
                finalizeCurrentToken()
                tokens.append(Token(value: String(char))) // store the new delimiter token
                continue
            }
            
            currentToken.append(String(char))
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
        currentToken = ""
        isInsideString = false
    }
}

private struct TokenChar {
    
    static let delimiters : [Character] = [mapOpen, mapClose, arrayOpen, arrayClose, keyValueDelimiter, elementDelimiter]
    
    static let stringDelimiter : Character = "\""
    static let stringEscape : Character = "\\"
    static let whitespace : [Character] = [" ", "\n", "\r", "\t"]
    
    static let mapOpen : Character = "{"
    static let mapClose : Character = "}"
    static let arrayOpen : Character = "["
    static let arrayClose : Character = "]"
    static let keyValueDelimiter : Character = ":"
    static let elementDelimiter : Character = ","
    
    static let null = "null"
    static let `true` = "true"
    static let `false` = "false"
    
    static func isWhitespace(_ char: Character) -> Bool {
        whitespace.contains(char)
    }
}

private class LiteralParser {

    static func parse(_ tokens: [Token]) -> [LiteralToken] {
        
        var itokens = [LiteralToken]()
        for token in tokens {
            if token.value.count == 1 {
                let char = Array(token.value)[0]
                switch char {
                case TokenChar.mapOpen:     itokens.append(.mapOpen)
                case TokenChar.mapClose:    itokens.append(.mapClose)
                case TokenChar.arrayOpen:   itokens.append(.arrayOpen)
                case TokenChar.arrayClose:  itokens.append(.arrayClose)
                case TokenChar.keyValueDelimiter:   itokens.append(.keyValueDelimiter)
                case TokenChar.elementDelimiter:    itokens.append(.elementDelimiter)
                default: fatalError("Uknown character: \(char)")
                }
            }
            else if token.isString {
                itokens.append(.literalValue(.string(token.value)))
                continue
            }
            else if token.value.lowercased() == TokenChar.null {
                itokens.append(.literalValue(.null(NSNull())))
            }
            else if token.value.lowercased() == TokenChar.true {
                itokens.append(.literalValue(.bool(true)))
            }
            else if token.value.lowercased() == TokenChar.false {
                itokens.append(.literalValue(.bool(false)))
            }
            else if let number = Double(token.value) {
                itokens.append(.literalValue(.number(number)))
            }
            else {
                fatalError("Unexpected value: \(token.value)")
            }
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

