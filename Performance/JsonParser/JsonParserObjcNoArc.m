#import "JsonParserObjcNoArc.h"
#import "Shared.h"



@interface NAToken : NSObject
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
- (void) resetValue;

@end

@implementation NAToken

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

- (void) resetValue {
    [value release];
    value = nil;
}

- (oneway void) release {
    [value release];
    value = nil;
    [super release];
}

@end

@interface NAJsonMap: NSObject
{
    @public
    NSMutableDictionary * value;
    NSString * key;
}
- (bool) isComplete;
- (void) consume: (__unsafe_unretained id) value;
- (id) value;
@end

@implementation NAJsonMap

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
        [key retain];
    }
    else {
        value[key] = newValue;
        [key release];
        key = nil;
    }
}

- (__unsafe_unretained id) value {
    return value;
}

- (oneway void) release {
    [value release];
    value = nil;
    [super release];
}

@end


@interface NAArray : NSObject
{
    NSMutableArray * value;
}
@end

@implementation NAArray

- (id) value {
    return self->value;
}

- (void) consume: (__unsafe_unretained id) newValue
{
    [self->value addObject: newValue];
}

- (bool) isComplete {
    return true;
}

- (oneway void) release {
    [value release];
    value = nil;
    [super release];
}

@end


@interface JsonParserObjcNoArc ()
{
    NSMutableArray<NAToken*>* tokens;
    NAToken* currentToken;
    bool isInsideString;
    bool isEscape;
    NSMutableArray * stack;
    id result;
}

@end

@implementation JsonParserObjcNoArc

- (instancetype)init {
    self = [super init];
    return self;
}

- (void) prepare {
    tokens = [[NSMutableArray alloc] init];
    [tokens retain];
    [self resetCurrentTokenWithIndex: 0];
    isInsideString = false;
    isEscape = false;
    stack = [[NSMutableArray alloc] init];
    [stack retain];
    result = [NSNull null];
}

- (void) tearDown {
    for (NAToken * t in tokens) {
        [t release];
    }
    [tokens release];
    tokens = nil;
    
    [currentToken release];
    currentToken = nil;
    
    isInsideString = false;
    isEscape = false;
    
    [stack release];
    stack = nil;
    
    [result release];
    result = nil;
}

- (void) resetCurrentTokenWithIndex: (int) i {
    [currentToken release];
    currentToken = [[NAToken alloc] initWithIndex:i length:0 isString:false];
    [currentToken retain];
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
    for(NAToken * token in tokens) {
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
        NAToken* token = tokens[i];
        
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
                    NSNumber * number = [JsonParserObjcNoArc
                                         tryMakeDoubleWithStartIndex: token->index
                                         length: token->length
                                         bytes: bytes];
                    
                    if (number != nil) {
                        token->value = number;
                        [token->value retain];
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
            [token->value retain];
            token->type = TokenType_Value_String;
            continue;
        }
        
        if (token->length == 4) {
            if (    (bytes[token->index + 0] == 't' || bytes[token->index + 0] == 'T')
                 && (bytes[token->index + 1] == 'r' || bytes[token->index + 1] == 'R')
                 && (bytes[token->index + 2] == 'u' || bytes[token->index + 2] == 'U')
                 && (bytes[token->index + 3] == 'e' || bytes[token->index + 3] == 'E'))
            {
                token->value = [NSNumber numberWithBool:true];
                [token->value retain];
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
            if (    (bytes[token->index + 0] == 'f' || bytes[token->index + 0] == 'F')
                 && (bytes[token->index + 1] == 'a' || bytes[token->index + 1] == 'A')
                 && (bytes[token->index + 2] == 'l' || bytes[token->index + 2] == 'L')
                 && (bytes[token->index + 3] == 's' || bytes[token->index + 3] == 'S')
                 && (bytes[token->index + 4] == 'e' || bytes[token->index + 4] == 'E'))
            {
                token->value = [NSNumber numberWithBool:false];
                [token->value retain];
                token->type = TokenType_Value_Bool;
            }
            continue;
        }
        
        // parse double
        
        NSNumber * number = [JsonParserObjcNoArc
                             tryMakeDoubleWithStartIndex: token->index
                             length: token->length
                             bytes: bytes];
        
        if (number != nil) {
            token->value = number;
            [token->value retain];
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
        NAToken * token = tokens[0];
        TokenType type = token->type;
        switch (type) {
            case TokenType_Value_String:
            case TokenType_Value_Number:
            case TokenType_Value_Bool:
            case TokenType_Value_Null:
                result = token->value;
                [result retain];
                [token resetValue];
                return;
            default:
                NSLog(@"Invalid single token: %@", token->value);
                exit(EXIT_FAILURE);
        }
    }
    
    for (int i=0; i<tokens.count; i++) {
        NAToken * token = tokens[i];
        TokenType type = token->type;
        switch (type) {
            case TokenType_Unresolved: {
                NSLog(@"Token type unresolved: %@", token->value);
                exit(EXIT_FAILURE);
                break;
            }
            case TokenType_MapOpen: {
                [stack addObject: [NAJsonMap new]];
                break;
            }
            case TokenType_MapClose: {
                [self popStack];
                break;
            }
            case TokenType_ArrayOpen: {
                [stack addObject: [[NAArray alloc] init]];
                break;
            }
            case TokenType_ArrayClose: {
                [self popStack];
                break;
            }
            case TokenType_KeyValueDelimiter: {
#ifdef DEBUG
                // validations only
                id current = stack.lastObject;
                if ([current isComplete]) {
                    NSLog(@"Found the key-value separator without a key being set previously");
                    exit(EXIT_FAILURE);
                }
#endif
                break;
            }
            case TokenType_ElementDelimiter:{
#ifdef DEBUG
                id current = stack.lastObject;
                if (![current isComplete]) { // will crash if wrong type
                    NSLog(@"Found the element delimiter but the map is not complete"); // only map can be incomplete (key:val), array is always complete
                    exit(EXIT_FAILURE);
                }
#endif
                break;
            }
            case TokenType_Value_Null:
            case TokenType_Value_Bool:
            case TokenType_Value_Number:
            case TokenType_Value_String: {
                id current = stack.lastObject;
                [current consume: token->value]; // will fail if wrong type
                [token resetValue];
                break;
            }
        }
    }
}

- (void) popStack {
    id current = stack.lastObject;
    [stack removeLastObject];
    id parent = stack.lastObject;
    if (parent != nil) {
        [parent consume: [current value]];
        [current release];
    }
    else {
#ifdef DEBUG
        if (![current isComplete]) {
            NSLog(@"Completing a collection, but the map is not complete");
            exit(EXIT_FAILURE);
        }
#endif
        result = [current value];
        [result retain];
        [current release];
    }
}

@end
