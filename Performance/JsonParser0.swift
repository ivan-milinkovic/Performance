import Foundation

// problem: chars get swallowed between state changes, because iterator always advances
// fix: remember carry over char and don't do iter.next() if it is present, just process the current one with the new state

class JsonParser0 {
    
    enum ParserState {
        case anyValue(AnyValue)
        case map(Map)
        case array(Array)
        case key(MapKey)
        case literal(Literal)
        
        var value: Any {
            switch self {
            case .anyValue(let value)  : return value.value
            case .map(let map)         : return map.value
            case .array(let array)     : return array.value
            case .key(let key)         : return key.value
            case .literal(let literal) : return literal.value
            }
        }
        
        func consume(_ state: ParserState) {
            switch self {
            case .anyValue(let value) : value.value = state.value
            case .map(let map)        :
                if map.key == nil {
                    map.key = (state.value as! String)
                }
                else {
                    map.val = state.value
                }
            case .array(let array)    : array.value.append(state.value)
            case .key(_)              : fatalError("ParseState.MapKey cannot consume a result from another state")
            case .literal(_)          : fatalError("ParseState.Literal cannot consume a result from another state")
            }
        }
        
    }
    
    class AnyValue {
        var value: Any = ""
    }
    
    class Map {
        var value = [String: Any]()
        var key: String?
        var val: Any?
    }
    
    class Array {
        var value = [Any]()
    }
    
    class MapKey {
        var value = ""
        var escapeFlag = false
    }
    
    class Literal {
        var value : String = ""
        var isString = false // needs to handle escaping in the content of value
        var escapeFlag = false
        init(firstChar: Character?) {
            if let firstChar {
                self.value.append(firstChar)
            }
            self.isString = (firstChar == TokenString.stringOpenClose)
            self.escapeFlag = false
        }
    }
    
    private var currentState : ParserState {
        stateStack.top()!
    }
    private var stateStack = Stack<ParserState>() // does not contain the current state
    
    init() {
        let initialState = ParserState.anyValue(AnyValue())
        pushState(initialState)
    }
    
    func parse(jsonString str: String) -> Any {
        
        var strIter = str.makeIterator()
        while let char = strIter.next() {
            switch currentState {
            case .anyValue             : handleAnyValue(char)
            case .map(let map)         : handleMap(map, char)
            case .array(let array)     : handleArray(array, char: char)
            case .key(let key)         : handleKey(key, char: char)
            case .literal(let literal) : handleLiteral(literal, char: char)
            }
        }
        
        // unwind state
        while stateStack.count > 1 {
            popState()
        }
        
        if stateStack.count > 1 {
            fatalError("Invalid json")
        }
        
        return stateStack.pop().value
    }
    
    private func startMap() {
        let mapState = ParserState.map(Map())
        pushState(mapState)
        let keyState = ParserState.key(MapKey())
        pushState(keyState)
    }
    
    private func pushState(_ newState: ParserState) {
        stateStack.push(newState)
    }
    
    private func popState() {
        let currentState = stateStack.pop()
        let parentState = stateStack.top()!
        parentState.consume(currentState)
    }
    
    private func handleAnyValue(_ char: Character) {
        
        if TokenString.isWhitespace(char) { return }

        switch char {
        case TokenString.mapOpen:
            let nextState = ParserState.map(Map())
            pushState(nextState)
        
        case TokenString.arrayOpen:
            let nextState = ParserState.array(Array())
            pushState(nextState)
        
        default:
            let nextState = ParserState.literal(Literal(firstChar: char))
            pushState(nextState)
        }
    }
    
    private func handleMap(_ map: Map, _ char: Character) {
        
        if TokenString.isWhitespace(char) { return }
        
        if map.key == nil {
            switch char {
            case TokenString.stringOpenClose:
                let mapKey = MapKey()
                pushState(.key(mapKey))
                
            case TokenString.mapClose:
                popState()
                
            default:
                fatalError("unexpected token: \(char)")
            }
        }
        else if map.val == nil {
            switch char {
            case TokenString.keyValueDelimiter:
                pushState(.literal(Literal(firstChar: nil)))
            default:
                fatalError("unexpected token: \(char)")
            }
        }
        else {
            switch char {
            case TokenString.elementDelimiter:
                return
            case TokenString.mapClose:
                popState()
            default:
                fatalError("unexpected token: \(char)")
            }
        }
    }
    
    // array is not used
    private func handleArray(_ array: Array, char: Character) {
        
        if TokenString.isWhitespace(char) { return }
        
        if char == TokenString.elementDelimiter {
            return
        }
        if char == TokenString.arrayClose {
            popState()
        }
        
        switch char {
        case TokenString.elementDelimiter:
            return
        
        case TokenString.arrayClose:
            popState()
        
        default:
            let newState = ParserState.anyValue(AnyValue())
            pushState(newState)
            handleAnyValue(char)
        }
    }
    
    private func handleKey(_ key: MapKey, char: Character) {
        if key.escapeFlag { return } // skip to next char
        
        // Accept new char
        
        if char == TokenString.stringEscape {
            key.escapeFlag = true
            return
        }
        
        if char == TokenString.stringOpenClose {
            popState()
        }
        
        key.value.append(char)
        key.escapeFlag = false
    }
    
    private func handleLiteral(_ literal: Literal, char: Character) {
        if literal.value.isEmpty {
            if TokenString.isWhitespace(char) { return }
            literal.isString = (char == TokenString.stringOpenClose)
            if literal.isString { return }
            literal.value.append(char)
            return
        }
        
        let collectionClosingChars = [TokenString.mapClose, TokenString.arrayClose, TokenString.elementDelimiter]
        if collectionClosingChars.contains(char) {
            popState() // pop self
            popState() // pop parent collection
            return
        }
        
        literal.value.append(char)
    }
    
    struct TokenString {
        
        static let mapOpen : Character = "{"
        static let mapClose : Character = "}"
        
        static let arrayOpen : Character = "["
        static let arrayClose : Character = "]"
        
        static let keyValueDelimiter : Character = ":"
        static let elementDelimiter : Character = ","
        static let stringOpenClose : Character = "\""
        static let stringEscape : Character = "\\"
        
        static func isWhitespace(_ char: Character) -> Bool {
            " \n\r".contains(char)
        }
    }
    
}
