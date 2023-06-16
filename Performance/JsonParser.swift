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
        return tokens.joined(separator: " ")
    }
}

private typealias Token = String

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
                    isInsideString = false
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
            
            if TokenChar.tokens.contains(char) {
                finalizeCurrentToken()
                tokens.append(String(char)) // store the new delimiter token
                continue
            }
            
            currentToken.append(String(char))
        }
        finalizeCurrentToken()
        return tokens
    }
    
    private func finalizeCurrentToken() {
        if !currentToken.isEmpty {
            tokens.append(currentToken)
            currentToken = ""
        }
    }
}

struct TokenChar {
    static let tokens : [Character] = ["{", "}", "[", "]", ",", ":"]
    static let stringDelimiter : Character = "\""
    static let stringEscape : Character = "\\"
    static let whitespace : [Character] = [" ", "\n", "\r"]
    
    static func isWhitespace(_ char: Character) -> Bool {
        whitespace.contains(char)
    }
}

/*
{
    "key1" : "value1",
    "key2" : "value 2",
    "key3" : [ "value\"3" ],
    "key4" : {
     "key4_1" : 123.234
    }
}

 */
