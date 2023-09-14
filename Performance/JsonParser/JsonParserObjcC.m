#import "JsonParserObjcC.h"
#import "Shared.h"
#import <objc/runtime.h>

// po [[NSString alloc] initWithBytes:(bytes + currentToken->index) length:currentToken->length encoding:NSUTF8StringEncoding];
// p ((__bridge OCCToken*)ocarray_get(&tokens, 0))->index
// p ((__bridge OCCToken*)ocarray_get(&tokens, 0))->length
// p (*((__bridge OCCToken**)ocarray_get(&tokens, 0)))->index

typedef struct {
    void * ptr;
    int capacity;
    int elsize;
    int index;
} OCArray;

void ocarray_init(OCArray * ocarray, int capacity, int elsize) {
    ocarray->ptr = malloc(capacity * elsize);
    ocarray->capacity = capacity;
    ocarray->elsize = elsize;
    ocarray->index = 0;
}

void ocarray_deinit(OCArray * ocarray) {
    free(ocarray->ptr);
}

void ocarray_resize(OCArray * oca) {
    int new_capacity = -1;
    int current_capacity = oca->capacity;
    if (current_capacity <= 10) {
        new_capacity = 2 * current_capacity;
    }
    else if (current_capacity < 100) {
        new_capacity = 1.5 * current_capacity;
    }
    else {
        new_capacity = 1.3 * current_capacity;
    }
    void * new_ptr = malloc(new_capacity * oca->elsize);
    memcpy(new_ptr, oca->ptr, oca->capacity * oca->elsize);
    void * old_ptr = oca->ptr;
    oca->ptr = new_ptr;
    oca->capacity = new_capacity;
    free(old_ptr);
}

void ocarray_add(OCArray * oca, const void * src, int srcsize) {
    int needs = oca->elsize * (oca->index + 1);
    if (needs >= oca->capacity) {
        ocarray_resize(oca);
    }
    void * dst = oca->ptr + (oca->elsize * oca->index);
    memcpy(dst, src, srcsize);
    oca->index++;
}

void * ocarray_get(OCArray * ocarray, int index) {
    return ocarray->ptr + (index * ocarray->elsize);
}

typedef struct {
    int index;
    int length;
    bool isString;
    
    TokenType type;
    id value;
} OCToken;

NSString * desc(OCToken * token, char * bytes) {
    return [[NSString alloc] initWithBytes:(bytes + token->index) length:token->length encoding:NSUTF8StringEncoding];
}

@interface OCCJsonMap: NSObject
{
    @public
    NSMutableDictionary * value;
    NSString * key;
}
- (bool) isComplete;
- (void) consume: (__unsafe_unretained id) value;
- (id) value;
@end

@implementation OCCJsonMap

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


@interface OCCArray : NSObject
{
    NSMutableArray * value;
}
@end

@implementation OCCArray

- (id) value {
    return value;
}

- (void) consume: (__unsafe_unretained id) newValue
{
    [self->value addObject: newValue];
}

- (bool) isComplete {
    return true;
}

@end


@interface JsonParserObjcC ()
{
    // use c array
    OCArray tokens;
    OCToken currentToken;
    bool isInsideString;
    bool isEscape;
    NSMutableArray * stack;
    id result;
}

@end

@implementation JsonParserObjcC

- (instancetype)init {
    self = [super init];
    return self;
}

- (void) prepare:(int) size {
    ocarray_init(&tokens, size, sizeof(OCToken));
    [self resetCurrentTokenWithIndex: 0];
    isInsideString = false;
    isEscape = false;
    stack = [[NSMutableArray alloc] init];
    result = [NSNull null];
}

- (void) tearDown {
    ocarray_deinit(&tokens);
    isInsideString = false;
    isEscape = false;
    stack = nil;
    result = nil;
}

- (void) resetCurrentTokenWithIndex: (int) i {
    currentToken.index = i;
    currentToken.length = 0;
    currentToken.isString = false;
    
    isInsideString = false;
}

- (id) parseString:(NSString *) string {
    NSData * data = [string dataUsingEncoding: NSUTF8StringEncoding];
    return [self parse: data];
}

- (id) parse:(NSData *) data {
    
    [self prepare: (int)data.length * sizeof(OCToken)];
    
//    OCCToken * t1 = [[OCCToken alloc] initWithIndex:0xAAAAAAAA length:0xBBBBBBBB isString:false];
//    OCCToken * t2 = [[OCCToken alloc] initWithIndex:3 length:4 isString:false];
//    const void * t1p = (__bridge const void *)(t1);
//    int t1s = (int) class_getInstanceSize(OCCToken.class);
//    const void ** t1pp = &t1p;
//    ocarray_add(&tokens, t1pp, sizeof(void *));
//    ocarray_add(&tokens, &t2, sizeof(void *));
    
    [self tokenize: data];
//    return NSNull.null;
    
    [self parseLiterals: data];
    [self parseCollections];
    
    id resultCopy = result;
    [self tearDown];
    return resultCopy;
}

- (void) printTokens:(NSData *) data {
    const char* const bytes = data.bytes;
    for(int i=0; i<tokens.index; i++) {
        OCToken * ptoken = ocarray_get(&tokens, i);
        NSString * str = [[NSString alloc] initWithBytes:(bytes + ptoken->index) length:ptoken->length encoding: NSUTF8StringEncoding];
        NSLog(@"token: at: %d, %@", ptoken->index, str);
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
                currentToken.length++;
                continue;
            }
            if (cha == CHAR_STRING_DELIMITER) {
                if (isEscape) {
                    isEscape = false;
                    currentToken.length++;
                    continue;
                }
                currentToken.length++;
                [self finalizeCurrentTokenAtIndex: i];
                continue;
            }
            
            currentToken.length++;
            continue;
        }
        
        if ([self isWhitespace: cha]) {
            if (currentToken.length == 0) {
                currentToken.index++;
            } else {
                [self finalizeCurrentTokenAtIndex: i];
            }
            continue;
        }
        
        if (cha == CHAR_STRING_DELIMITER) {
            isInsideString = true;
            currentToken.length++;
            continue;
        }
        
        if ([self isDelimiter: cha]) {
            [self finalizeCurrentTokenAtIndex: i];
            currentToken.index = i;
            currentToken.length = 1;
            [self finalizeCurrentTokenAtIndex: i];
            continue;
        }
        
        currentToken.length++;
    }
    
    [self finalizeCurrentTokenAtIndex: i];
}

- (void) finalizeCurrentTokenAtIndex: (int) i {
    if (currentToken.length > 0) {
        currentToken.isString = isInsideString;
        ocarray_add(&tokens, &currentToken, tokens.elsize);
    }
    [self resetCurrentTokenWithIndex: i + 1]; // don't reset the token if it wasn't updated, just reuse the existing instance and update the index
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
    
    for (int i=0; i<tokens.index; i++) {
        OCToken * ptoken = ocarray_get(&tokens, i);
        
        if (ptoken->length == 1) {
            char c = bytes[ptoken->index];
            switch (c) {
                case CHAR_MAP_OPEN:
                    ptoken->type = TokenType_MapOpen;
                    break;
                case CHAR_MAP_CLOSE:
                    ptoken->type = TokenType_MapClose;
                    break;
                case CHAR_ARRAY_OPEN:
                    ptoken->type = TokenType_ArrayOpen;
                    break;
                case CHAR_ARRAY_CLOSE:
                    ptoken->type = TokenType_ArrayClose;
                    break;
                case CHAR_KEY_VALUE_DELIMITER:
                    ptoken->type = TokenType_KeyValueDelimiter;
                    break;
                case CHAR_ELEMENT_DELIMITER:
                    ptoken->type = TokenType_ElementDelimiter;
                    break;
                default: {
                    NSNumber * number = tryMakeDouble(ptoken->index, ptoken->length, bytes);
                    if (number != nil) {
                        ptoken->value = number;
                        ptoken->type = TokenType_Value_Number;
                    } else {
                        NSLog(@"Unexpected char: %c", c);
                        exit(EXIT_FAILURE);
                    }
                    break;
                }
            }
            continue;
        }
        
        if (ptoken->isString) {
            ptoken->value = [[NSString alloc]
                            initWithBytes:(bytes + ptoken->index + 1)
                            length:ptoken->length - 2
                            encoding: NSUTF8StringEncoding];
            ptoken->type = TokenType_Value_String;
            continue;
        }
        
        if (ptoken->length == 4) {
//            if (0 == memcmp(bytes + token->index, "true", 4)) {
//                token->value = [NSNumber numberWithBool:true];
//                token->type = TokenType_Value_Bool;
//            }
//
//            if (0 == memcmp(bytes + token->index, "null", 4)) {
//                token->value = [NSNull null];
//                token->type = TokenType_Value_Null;
//            }
            
            if (    (bytes[ptoken->index + 0] == 't' || bytes[ptoken->index + 0] == 'T')
                 && (bytes[ptoken->index + 1] == 'r' || bytes[ptoken->index + 1] == 'R')
                 && (bytes[ptoken->index + 2] == 'u' || bytes[ptoken->index + 2] == 'U')
                 && (bytes[ptoken->index + 3] == 'e' || bytes[ptoken->index + 3] == 'E'))
            {
                ptoken->value = [NSNumber numberWithBool:true];
                ptoken->type = TokenType_Value_Bool;
            }
            
            if (    (bytes[ptoken->index + 0] == 'n' || bytes[ptoken->index + 0] == 'N')
                 && (bytes[ptoken->index + 1] == 'u' || bytes[ptoken->index + 1] == 'U')
                 && (bytes[ptoken->index + 2] == 'l' || bytes[ptoken->index + 2] == 'L')
                 && (bytes[ptoken->index + 3] == 'l' || bytes[ptoken->index + 3] == 'L'))
            {
                ptoken->value = [NSNull null];
                ptoken->type = TokenType_Value_Null;
            }
            
            continue;
        }
        
        if (ptoken->length == 5) {
//            if (0 == memcmp(bytes + token->index, "false", 4)) {
//                token->value = [NSNumber numberWithBool:false];
//                token->type = TokenType_Value_Bool;
//            }
            
            if (    (bytes[ptoken->index + 0] == 'f' || bytes[ptoken->index + 0] == 'F')
                 && (bytes[ptoken->index + 1] == 'a' || bytes[ptoken->index + 1] == 'A')
                 && (bytes[ptoken->index + 2] == 'l' || bytes[ptoken->index + 2] == 'L')
                 && (bytes[ptoken->index + 3] == 's' || bytes[ptoken->index + 3] == 'S')
                 && (bytes[ptoken->index + 4] == 'e' || bytes[ptoken->index + 4] == 'E'))
            {
                ptoken->value = [NSNumber numberWithBool:false];
                ptoken->type = TokenType_Value_Bool;
            }
            continue;
        }
        
        // parse double
        
//        NSString * str = [[NSString alloc] initWithBytes:(bytes + token->index)
//                                 length:token->length
//                               encoding: NSUTF8StringEncoding];
//        NSNumberFormatter * fmt = [NSNumberFormatter new];
//        NSNumber * number = [fmt numberFromString: str];
        
        NSNumber * number = tryMakeDouble(ptoken->index, ptoken->length, bytes);
        if (number != nil) {
            ptoken->value = number;
            ptoken->type = TokenType_Value_Number;
            continue;
        }
        
        NSLog(@"Invalid token: %@, at index: %d", ptoken->value, i);
        exit(EXIT_FAILURE);
    }
}

- (void) parseCollections {
    
    if (tokens.index == 0) {
        result = NSNull.null;
        return;
    }
    
    if (tokens.index == 1) {
        OCToken * ptoken = ocarray_get(&tokens, 0);
        TokenType type = ptoken->type;
        switch (type) {
            case TokenType_Value_String:
            case TokenType_Value_Number:
            case TokenType_Value_Bool:
            case TokenType_Value_Null:
                result = ptoken->value;
                return;
            default:
                NSLog(@"Invalid single token: %@", ptoken->value);
                exit(EXIT_FAILURE);
        }
    }
    
    for (int i=0; i<tokens.index; i++) {
        OCToken * ptoken = ocarray_get(&tokens, i);
        TokenType type = ptoken->type;
        switch (type) {
            case TokenType_Unresolved: {
                NSLog(@"Token type unresolved: %@", ptoken->value);
                exit(EXIT_FAILURE);
                break;
            }
            case TokenType_MapOpen: {
                [stack addObject: [OCCJsonMap new]];
                break;
            }
            case TokenType_MapClose: {
                [self popStack];
                break;
            }
            case TokenType_ArrayOpen: {
                [stack addObject: [OCCArray new]];
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
                [current consume: ptoken->value]; // will fail if wrong type
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
        [parent consume: [current value]]; // will fail if wrong type
    }
    else {
#ifdef DEBUG
        if (![current isComplete]) {
            NSLog(@"Completing a collection, but the map is not complete");
            exit(EXIT_FAILURE);
        }
#endif
        result = [current value];
    }
}

@end
