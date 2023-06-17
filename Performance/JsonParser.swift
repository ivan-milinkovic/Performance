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
//        print(tokens.map(\.value).joined(separator: " "))
        let itokens = IntermediateParser.parse(tokens)
        return itokens.map(\.description).joined(separator: " ")
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
        return tokens
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
    static let whitespace : [Character] = [" ", "\n", "\r"]
    
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

private class IntermediateParser {

    static func parse(_ tokens: [Token]) -> [IntermediateToken] {
        
        var itokens = [IntermediateToken]()
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

private enum IntermediateToken {
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

extension IntermediateToken: CustomStringConvertible {
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
    
    var current: JsonCollection? = nil
    
    func parse(_ itokens: [IntermediateToken]) -> Any {
        
        if itokens.count == 0 { return NSNull() }
        
        if itokens.count == 1,
           case .literalValue(let literalValue) = itokens.first! {
            return literalValue
        } else {
            fatalError("Invalid json")
        }
        
        for itoken in itokens {
            switch itoken {
            case .mapOpen:
                break
            case .mapClose:
                break
            case .arrayOpen:
                break
            case .arrayClose:
                break
            case .keyValueDelimiter:
                break
            case .elementDelimiter:
                break
            case .literalValue(let literalValue):
                break
            }
        }
    }
}

private enum JsonCollection {
    case map(JsonMap)
    case array(JsonArray)
}

private class JsonMap {
    var value = [String: Any]()
    var key: String?
    var val: Any?
}

private class JsonArray {
    var value = [Any]()
}

