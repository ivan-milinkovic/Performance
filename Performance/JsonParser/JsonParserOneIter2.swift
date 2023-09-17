import Foundation

// Attempts to do both tokenization and value parsing and collections in one go.

// slow: string iterator, string append


final class JsonParserOneIter2 {
    
    enum ParserState {
        case any(AnyValue)
        case map(Map)
        case array(Array)
        case key(MapKey)
        case literal(Literal)
        
        var value: Any {
            switch self {
            case .any(let value)       : return value.value
            case .map(let map)         : return map.value
            case .array(let array)     : return array.value
            case .key(let key)         : return key.value
            case .literal(let literal) : return literal.finalValue
            }
        }
        
        func consume(_ state: ParserState) {
            switch self {
            case .any(let value) : value.value = state.value
            case .map(let map)        :
                if map.key == nil {
                    map.key = (state.value as! String)
                }
                else {
                    map.value[map.key!] = state.value
                    map.key = nil
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
    }
    
    class Array {
        var value = [Any]()
    }
    
    class MapKey {
        var value = ""
        var escapeFlag = false
    }
    
    class Literal {
        var index = 0
        var length = 0
        var isString = false // needs to handle escaping in the content of value
        var escapeFlag = false
        var finalValue : Any = 0
        init(index: Int) {
            self.index = index
            self.escapeFlag = false
        }
        func resolveValue(_ data: Data) {
            if isString {
                let subdata = data[index..<index+length]
                finalValue = String(data: subdata, encoding: .utf8)!
            }
            else {
                finalValue = tryMakeDouble(startIndex: index, length: length, data: data) ?? 0.0
            }
            // todo: parse false/true/null
        }
    }
    
    private var currentState : ParserState {
        stateStack.top()!
    }
    private var stateStack = Stack<ParserState>() // does not contain the current state
    
    init() {
        let initialState = ParserState.any(AnyValue())
        pushState(initialState)
    }
    
    var data: Data!
    var i = 0
    
    func parse(data: Data) -> Any {
        self.data = data
        var dataIter = data.makeIterator()
        while let byte = dataIter.next() {
            let char = Character(UnicodeScalar(byte))
            switch currentState {
            case .any                  : handleAnyValue(char)
            case .map(let map)         : handleMap(map, char)
            case .array(let array)     : handleArray(array, char: char)
            case .key(let key)         : handleKey(key, char: char)
            case .literal(let literal) : handleLiteral(literal, char: char)
            }
            i += 1
        }
        
        // The stack always has .any as root
        while stateStack.count > 1 {
            popState()
        }
        
        if stateStack.count > 1 {
            fatalError("Stack did not unwind")
        }
        
        return stateStack.pop().value
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
        
        if TokenChar.isWhitespace(char) { return }

        switch char {
        case TokenChar.mapOpen:
            let nextState = ParserState.map(Map())
            pushState(nextState)
        
        case TokenChar.arrayOpen:
            let nextState = ParserState.array(Array())
            pushState(nextState)
            
        case TokenChar.stringOpenClose:
            let lit = Literal(index: i+1)
            lit.isString = true
            let nextState = ParserState.literal(lit)
            pushState(nextState)
        
        default:
            let nextState = ParserState.literal(Literal(index: i))
            pushState(nextState)
        }
    }
    
    private func handleMap(_ map: Map, _ char: Character) {
        
        if TokenChar.isWhitespace(char) { return }
        
        if map.key == nil {
            switch char {
            case TokenChar.stringOpenClose:
                let mapKey = MapKey()
                pushState(.key(mapKey))
                
            case TokenChar.mapClose:
                popState()
                
            case TokenChar.elementDelimiter:
                return
                
            default:
                fatalError("unexpected token: \(char)")
            }
        }
        else {
            switch char {
            case TokenChar.keyValueDelimiter:
                pushState(.any(AnyValue()))
//                pushState(.literal(Literal(firstChar: nil)))
            default:
                fatalError("unexpected token: \(char)")
            }
        }
//        else {
//            switch char {
//            case TokenString.elementDelimiter:
//                return
//            case TokenString.mapClose:
//                popState()
//            default:
//                fatalError("unexpected token: \(char)")
//            }
//        }
    }
    
    private func startMap() {
        let mapState = ParserState.map(Map())
        pushState(mapState)
        let keyState = ParserState.key(MapKey())
        pushState(keyState)
    }
    
    
    // array is not used
    private func handleArray(_ array: Array, char: Character) {
        
        if TokenChar.isWhitespace(char) { return }
        
        switch char {
        case TokenChar.elementDelimiter:
            return
        
        case TokenChar.arrayClose:
            popState()
            return
        
        default:
            let newState = ParserState.any(AnyValue())
            pushState(newState)
            handleAnyValue(char)
        }
    }
    
    private func handleKey(_ key: MapKey, char: Character) {
        if key.escapeFlag { return } // skip to next char
        
        // Accept new char
        
        if char == TokenChar.stringEscape {
            key.escapeFlag = true
            return
        }
        
        if char == TokenChar.stringOpenClose {
            popState()
            return
        }
        
        key.value.append(char)
        key.escapeFlag = false
    }
    
    private func handleLiteral(_ literal: Literal, char: Character) {
        if literal.length == 0 {
//            if TokenString.isWhitespace(char) { return }
            literal.isString = (char == TokenChar.stringOpenClose)
            if literal.isString { return }
            literal.length += 1
            return
        }
        
        if TokenChar.isWhitespace(char) || char == TokenChar.stringOpenClose || char == TokenChar.elementDelimiter {
            literal.resolveValue(data)
            popState()
            popState() // pop any
            return
        }
        
        let collectionClosingChars = [TokenChar.mapClose, TokenChar.arrayClose]
        if collectionClosingChars.contains(char) {
            literal.resolveValue(data)
            popState() // pop self
            popState() // pop parent any
            popState() // pop parent collection
            popState() // pop parent's parent any collection
            return
        }
        
        literal.length += 1
    }
    
    struct TokenChar {
        
        static let mapOpen : Character = "{"
        static let mapClose : Character = "}"
        
        static let arrayOpen : Character = "["
        static let arrayClose : Character = "]"
        
        static let keyValueDelimiter : Character = ":"
        static let elementDelimiter : Character = ","
        static let stringOpenClose : Character = "\""
        static let stringEscape : Character = "\\"
        
        static let newLine : Character = "\n"
        static let carriageReturn : Character = "\r"
        
        static func isWhitespace(_ char: Character) -> Bool {
            char == newLine || char == carriageReturn
        }
    }
    
}
