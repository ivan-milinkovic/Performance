#import "JsonParserObjc.h"

const char CHAR_SPACE = ' ';
const char CHAR_NEWLINE = '\n';
const char CHAR_CARRIAGE = '\r';
const char CHAR_TAB = '\t';

const char CHAR_STRING_DELIMITER = '"';
const char CHAR_STRING_ESCAPE = '\\';

const char CHAR_MAP_OPEN = '{';
const char CHAR_MAP_CLOSE = '}';
const char CHAR_ARRAY_OPEN = '[';
const char CHAR_ARRAY_CLOSE = ']';
const char CHAR_KEY_VALUE_DELIMITER = ':';
const char CHAR_ELEMENT_DELIMITER = ',';

typedef NS_ENUM(short, TokenType) {
    TokenType_Unresolved,
    TokenType_MapOpen,
    TokenType_MapClose,
    TokenType_ArrayOpen,
    TokenType_ArrayClose,
    TokenType_KeyValueDelimiter,
    TokenType_ElementDelimiter,
    TokenType_Value_String,
    TokenType_Value_Number,
    TokenType_Value_Bool,
    TokenType_Value_Null
};

@interface Token : NSObject
{
    @public
    
    int index;
    int length;
    bool isString;
    
    TokenType type;
    id value;
}

- (id)init NS_UNAVAILABLE;
- (NSString*) desc:(char *)bytes;

@end

@implementation Token

- (instancetype)initWithIndex: (int) index
                       length: (int) length
                     isString: (bool) isString {
    self = [super init];
    self->index = index;
    self->length = length;
    self->isString = isString;
    
    type = TokenType_Unresolved;
    value = nil;
    
    return self;
}

- (NSString*) desc:(char *)bytes {
    return [[NSString alloc] initWithBytes:(bytes + index) length:length encoding:NSUTF8StringEncoding];
}

@end

@interface JsonMap: NSObject
{
    @public
    NSMutableDictionary * value;
    NSString * key;
}
- (bool) isComplete;
- (void) consume: (__unsafe_unretained id) value;
- (id) value;
@end

@implementation JsonMap

- (instancetype) init {
    self = [super init];
    value = [NSMutableDictionary new];
    key = nil;
    return self;
}

- (bool) isComplete {
    return key == nil;
}

- (void) consume: (__unsafe_unretained id) newValue {
    if (key == nil) {
        if (![newValue isKindOfClass:NSString.class]) {
            NSLog(@"Expected a map key, but got: %@", newValue);
            exit(EXIT_FAILURE);
        }
        key = newValue;
    }
    else {
        value[key] = newValue;
        key = nil;
    }
}

- (__unsafe_unretained id) value {
    return value;
}

@end


@interface NSMutableArray (Ext)
@end

@implementation NSMutableArray (Ext)

- (id) value {
    return self;
}

- (void) consume: (__unsafe_unretained id) newValue
{
    [self addObject: newValue];
}

@end


@interface JsonParserObjc ()
{
    NSMutableArray<Token*>* tokens;
    Token* currentToken;
    bool isInsideString;
    bool isEscape;
    NSMutableArray * stack;
    id result;
}

@end

@implementation JsonParserObjc

- (instancetype)init {
    self = [super init];
    return self;
}

- (void) prepare {
    tokens = [[NSMutableArray alloc] init];
    [self resetCurrentTokenWithIndex: 0];
    isInsideString = false;
    isEscape = false;
    stack = [[NSMutableArray alloc] init];
    result = [NSNull null];
}

- (void) tearDown {
    tokens = nil;
    currentToken = nil;
    isInsideString = false;
    isEscape = false;
    stack = nil;
    result = nil;
}

- (void) resetCurrentTokenWithIndex: (int) i {
    currentToken = [[Token alloc] initWithIndex:i length:0 isString:false];
    isInsideString = false;
}

- (id) parseString:(NSString *) string {
    NSData * data = [string dataUsingEncoding: NSUTF8StringEncoding];
    return [self parse: data];
}

- (id) parse:(NSData *) data {
    
    [self prepare];
    
    [self tokenize: data];
    [self parseLiterals: data];
    [self parseCollections];
    
    id resultCopy = result;
    [self tearDown];
    return resultCopy;
}

- (void) printTokens:(NSData *) data {
    const char* const bytes = data.bytes;
    for(Token * token in tokens) {
        NSString * str = [[NSString alloc] initWithBytes:(bytes + token->index) length:token->length encoding: NSUTF8StringEncoding];
        NSLog(@"token: at: %d, %@", token->index, str);
    }
}

- (void) tokenize: (__unsafe_unretained NSData *) data {
    const char* const bytes = data.bytes;
    int i=0;
    for (;i<data.length; i++)
    {
        char cha = bytes[i];
        
        if (isInsideString) {
            if (cha == CHAR_STRING_ESCAPE) {
                isEscape = true;
                currentToken->length++;
                continue;
            }
            if (cha == CHAR_STRING_DELIMITER) {
                if (isEscape) {
                    isEscape = false;
                    currentToken->length++;
                    continue;
                }
                currentToken->length++;
                [self finalizeCurrentTokenAtIndex: i];
                continue;
            }
            
            currentToken->length++;
            continue;
        }
        
        if ([self isWhitespace: cha]) {
            if (currentToken->length == 0) {
                currentToken->index++;
            } else {
                [self finalizeCurrentTokenAtIndex: i];
            }
            continue;
        }
        
        if (cha == CHAR_STRING_DELIMITER) {
            isInsideString = true;
            currentToken->length++;
            continue;
        }
        
        if ([self isDelimiter: cha]) {
            [self finalizeCurrentTokenAtIndex: i];
            currentToken->index = i;
            currentToken->length = 1;
            [self finalizeCurrentTokenAtIndex: i];
            continue;
        }
        
        currentToken->length++;
    }
    
    [self finalizeCurrentTokenAtIndex: i];
}

- (void) finalizeCurrentTokenAtIndex: (int) i {
    if (currentToken->length > 0) {
        currentToken->isString = isInsideString;
        [tokens addObject:currentToken];
    }
    [self resetCurrentTokenWithIndex: i + 1];
}

- (bool) isWhitespace: (char) cha {
    return cha == CHAR_SPACE
        || cha == CHAR_NEWLINE
        || cha == CHAR_CARRIAGE
        || cha == CHAR_TAB;
}

- (bool) isDelimiter: (char) cha {
    return cha == CHAR_MAP_OPEN
        || cha == CHAR_MAP_CLOSE
        || cha == CHAR_ARRAY_OPEN
        || cha == CHAR_ARRAY_CLOSE
        || cha == CHAR_KEY_VALUE_DELIMITER
        || cha == CHAR_ELEMENT_DELIMITER;
}

- (void) parseLiterals: (__unsafe_unretained NSData*) data {
    const char* const bytes = data.bytes;
    for (int i=0; i<tokens.count; i++) {
        Token* token = tokens[i];
        
        if (token->length == 1) {
            char c = bytes[token->index];
            switch (c) {
                case CHAR_MAP_OPEN:
                    token->type = TokenType_MapOpen;
                    break;
                case CHAR_MAP_CLOSE:
                    token->type = TokenType_MapClose;
                    break;
                case CHAR_ARRAY_OPEN:
                    token->type = TokenType_ArrayOpen;
                    break;
                case CHAR_ARRAY_CLOSE:
                    token->type = TokenType_ArrayClose;
                    break;
                case CHAR_KEY_VALUE_DELIMITER:
                    token->type = TokenType_KeyValueDelimiter;
                    break;
                case CHAR_ELEMENT_DELIMITER:
                    token->type = TokenType_ElementDelimiter;
                    break;
                default: {
                    NSNumber * number = [JsonParserObjc
                                         tryMakeDoubleWithStartIndex: token->index
                                         length: token->length
                                         bytes: bytes];
                    
                    if (number != nil) {
                        token->value = number;
                        token->type = TokenType_Value_Number;
                    } else {
                        NSLog(@"Unexpected char: %c", c);
                        exit(EXIT_FAILURE);
                    }
                    break;
                }
            }
            continue;
        }
        
        if (token->isString) {
            token->value = [[NSString alloc]
                            initWithBytes:(bytes + token->index + 1)
                            length:token->length - 2
                            encoding: NSUTF8StringEncoding];
            token->type = TokenType_Value_String;
            continue;
        }
        
        if (token->length == 4) {
//            if (0 == memcmp(bytes + token->index, "true", 4)) {
//                token->value = [NSNumber numberWithBool:true];
//                token->type = TokenType_Value_Bool;
//            }
//
//            if (0 == memcmp(bytes + token->index, "null", 4)) {
//                token->value = [NSNull null];
//                token->type = TokenType_Value_Null;
//            }
            
            if (    (bytes[token->index + 0] == 't' || bytes[token->index + 0] == 'T')
                 && (bytes[token->index + 1] == 'r' || bytes[token->index + 1] == 'R')
                 && (bytes[token->index + 2] == 'u' || bytes[token->index + 2] == 'U')
                 && (bytes[token->index + 3] == 'e' || bytes[token->index + 3] == 'E'))
            {
                token->value = [NSNumber numberWithBool:true];
                token->type = TokenType_Value_Bool;
            }
            
            if (    (bytes[token->index + 0] == 'n' || bytes[token->index + 0] == 'N')
                 && (bytes[token->index + 1] == 'u' || bytes[token->index + 1] == 'U')
                 && (bytes[token->index + 2] == 'l' || bytes[token->index + 2] == 'L')
                 && (bytes[token->index + 3] == 'l' || bytes[token->index + 3] == 'L'))
            {
                token->value = [NSNull null];
                token->type = TokenType_Value_Null;
            }
            
            continue;
        }
        
        if (token->length == 5) {
//            if (0 == memcmp(bytes + token->index, "false", 4)) {
//                token->value = [NSNumber numberWithBool:false];
//                token->type = TokenType_Value_Bool;
//            }
            
            if (    (bytes[token->index + 0] == 'f' || bytes[token->index + 0] == 'F')
                 && (bytes[token->index + 1] == 'a' || bytes[token->index + 1] == 'A')
                 && (bytes[token->index + 2] == 'l' || bytes[token->index + 2] == 'L')
                 && (bytes[token->index + 3] == 's' || bytes[token->index + 3] == 'S')
                 && (bytes[token->index + 4] == 'e' || bytes[token->index + 4] == 'E'))
            {
                token->value = [NSNumber numberWithBool:false];
                token->type = TokenType_Value_Bool;
            }
            continue;
        }
        
        // parse double
        
//        NSString * str = [[NSString alloc] initWithBytes:(bytes + token->index)
//                                 length:token->length
//                               encoding: NSUTF8StringEncoding];
//        NSNumberFormatter * fmt = [NSNumberFormatter new];
//        NSNumber * number = [fmt numberFromString: str];
        
        NSNumber * number = [JsonParserObjc
                             tryMakeDoubleWithStartIndex: token->index
                             length: token->length
                             bytes: bytes];
        
        if (number != nil) {
            token->value = number;
            token->type = TokenType_Value_Number;
            continue;
        }
        
        NSLog(@"Invalid token: %@, at index: %d", token->value, i);
        exit(EXIT_FAILURE);
    }
}

+ (NSNumber *) tryMakeDoubleWithStartIndex: (int) startIndex
                                    length: (int) length
                                     bytes: (const char *) bytes {

    bool hasDecimalPart = false;
    double num = 0.0;

    // int part
    char byte = bytes[startIndex];
    bool hasMinus = byte == '-';
    bool hasPlus = byte == '+';
    int startOffset = (hasMinus || hasPlus) ? 1 : 0;
    int endIndex = startIndex + length;
    
    int j = startIndex + startOffset;
    for (; j<endIndex; j++) {
        
        char byte = bytes[j];
        
        if (byte == '.') {
            hasDecimalPart = true;
            j++;
            break;
        }
        
        if (byte < '0' || byte > '9') {
            return nil;
        }
        
        int digit = byte - '0';
        num = num * 10.0 + digit;
    }
    
    if (hasDecimalPart) {
        
        double decimalPart = 0.0;
        
        for (int k=j; k<endIndex; k++) {
            char byte = bytes[k];
            if (byte < '0' || byte > '9') {
                return nil;
            }
            int digit = byte - '0';
            double exp = pow(10.0, k-j+1);
            decimalPart += ((double) digit) / exp;
        }
        
        num += decimalPart;
    }
    
    if (hasMinus) {
        num *= -1;
    }
    
    return [NSNumber numberWithDouble:num];
}

- (void) parseCollections {
    
    if (tokens.count == 0) {
        result = NSNull.null;
        return;
    }
    
    if (tokens.count == 1) {
        Token * token = tokens[0];
        TokenType type = token->type;
        switch (type) {
            case TokenType_Value_String:
            case TokenType_Value_Number:
            case TokenType_Value_Bool:
            case TokenType_Value_Null:
                result = token->value;
                return;
            default:
                NSLog(@"Invalid single token: %@", token->value);
                exit(EXIT_FAILURE);
        }
    }
    
    for (int i=0; i<tokens.count; i++) {
        Token * token = tokens[i];
        TokenType type = token->type;
        switch (type) {
            case TokenType_Unresolved: {
                NSLog(@"Token type unresolved: %@", token->value);
                exit(EXIT_FAILURE);
                break;
            }
            case TokenType_MapOpen: {
                [stack addObject: [JsonMap new]];
                break;
            }
            case TokenType_MapClose: {
                [self popStack];
                break;
            }
            case TokenType_ArrayOpen: {
                [stack addObject: [NSMutableArray new]];
                break;
            }
            case TokenType_ArrayClose: {
                [self popStack];
                break;
            }
            case TokenType_KeyValueDelimiter: {
                // validations only
                id current = stack.lastObject;
                if (![current isMemberOfClass:JsonMap.class]) {
                    NSLog(@"Expected a dictionary, got: %@", token->value);
                    exit(EXIT_FAILURE);
                }
                JsonMap * map = current;
                if (map->key == nil) {
                    NSLog(@"Found the key-value separator without a key being set previously");
                    exit(EXIT_FAILURE);
                }
                break;
            }
            case TokenType_ElementDelimiter:{
                id current = stack.lastObject;
                if (!([current isMemberOfClass:JsonMap.class] || [current isKindOfClass:NSMutableArray.class])) {
                    NSLog(@"Found the element delimiter but there's no collection instance");
                    exit(EXIT_FAILURE);
                }
                if ([current isMemberOfClass:JsonMap.class]) {
                    JsonMap* map = current;
                    if (!map.isComplete) {
                        NSLog(@"Found the element delimiter but the map is not complete");
                        exit(EXIT_FAILURE);
                    }
                    
                }
                break;
            }
            case TokenType_Value_Null:
            case TokenType_Value_Bool:
            case TokenType_Value_Number:
            case TokenType_Value_String: {
                id current = stack.lastObject;
                [self mergeInto:current value:token->value];
                break;
            }
        }
    }
}

- (void) mergeInto: (__unsafe_unretained id) collection
             value: (__unsafe_unretained id) newValue
{
    if (!([collection isMemberOfClass:JsonMap.class] || [collection isKindOfClass:NSMutableArray.class])) {
        NSLog(@"Found a value but there's no collection instance");
        exit(EXIT_FAILURE);
    }
    
    if ([collection isMemberOfClass:JsonMap.class]) {
        JsonMap* map = collection;
        [map consume: newValue];
    }
    if ([collection isKindOfClass:NSMutableArray.class]) {
        NSMutableArray* array = collection;
        [array addObject: newValue];
    }
}

- (void) popStack {
    id current = stack.lastObject;
    [stack removeLastObject];
    id parent = stack.lastObject;
    if (parent != nil) {
        [self mergeInto:parent value:[current value]];
    }
    else {
        if ([current isMemberOfClass:JsonMap.class]) {
            JsonMap * map = current;
            if (!map.isComplete) {
                NSLog(@"Completing a collection, but the map is not complete");
                exit(EXIT_FAILURE);
            }
        }
        result = [current value];
    }
}

@end
