#import "JsonParserObjcC.h"
#import "Shared.h"

#import <OSLog/OSLog.h>

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
    
    oca->ptr = realloc(oca->ptr, new_capacity * oca->elsize);
    oca->capacity = new_capacity;
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

@interface JsonParserObjcC ()
{
    @public
    
    // use c array
    OCArray tokens;
    OCToken currentToken;
    bool isInsideString;
    bool isEscape;
    NSMutableArray * stack;
    NSString * key; // when building a key value pair before putting them into a dictionary
    id result;
}

@end

@implementation JsonParserObjcC

- (instancetype)init {
    self = [super init];
    return self;
}

- (void) prepare:(int) size {
    ocarray_init(&tokens, 20, sizeof(OCToken));
    resetCurrentToken(self, 0);
    isInsideString = false;
    isEscape = false;
    stack = [[NSMutableArray alloc] init];
    result = [NSNull null];
}

- (void) tearDown {
    ocarray_deinit(&tokens);
    isInsideString = false;
    isEscape = false;
    [stack release];
    stack = nil;
    [key release];
    key = nil;
    result = nil;
}

void resetCurrentToken(__unsafe_unretained JsonParserObjcC * parser, int index) {
    parser->currentToken.index = index;
    parser->currentToken.length = 0;
    parser->currentToken.isString = false;
    parser->currentToken.type = TokenType_Unresolved;
    
    parser->isInsideString = false;
}

- (id) parseString:(NSString *) string {
    NSData * data = [string dataUsingEncoding: NSUTF8StringEncoding];
    return [self parse: data];
}

- (id) parse:(NSData *) data {
    
    int arraySize = 20; // (int)data.length * sizeof(OCToken);
    [self prepare: arraySize];
    [self tokenize: data];
    [self parseCollections: data];
    
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
    int i = 0;
    int cnt = (int) data.length;
    for (;i<cnt; i++)
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
                finalizeCurrentToken(self, i);
                continue;
            }
            
            currentToken.length++;
            continue;
        }
        
        bool is_whitespace = isWhitespace(cha);
        if (is_whitespace) {
            if (currentToken.length == 0) {
                currentToken.index++;
            } else {
                finalizeCurrentToken(self, i);
            }
            continue;
        }
        
        if (cha == CHAR_STRING_DELIMITER) {
            isInsideString = true;
            currentToken.length++;
            currentToken.type = TokenType_Value_String;
            continue;
        }
        
        bool is_delimiter = isDelimiter(cha);
        if (is_delimiter) {
            finalizeCurrentToken(self, i);
            currentToken.index = i;
            currentToken.length = 1;
            finalizeCurrentToken(self, i);
            continue;
        }
        
        currentToken.length++;
    }
    
    finalizeCurrentToken(self, i);
}

void finalizeCurrentToken(__unsafe_unretained JsonParserObjcC * parser, int i) {
    if (parser->currentToken.length > 0) {
        parser->currentToken.isString = parser->isInsideString;
        ocarray_add(&(parser->tokens), &(parser->currentToken), parser->tokens.elsize);
    }
    // don't reset the token if it wasn't updated, just reuse the existing instance and update the index
    resetCurrentToken(parser, i + 1);
}

bool isDelimiter(char cha) {
    return cha == CHAR_MAP_OPEN
        || cha == CHAR_MAP_CLOSE
        || cha == CHAR_ARRAY_OPEN
        || cha == CHAR_ARRAY_CLOSE
        || cha == CHAR_KEY_VALUE_DELIMITER
        || cha == CHAR_ELEMENT_DELIMITER;
}

static void parseTokenValue(OCToken * ptoken, const char *bytes) {
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
        return;
    }
    
    if (ptoken->isString) {
        ptoken->value = [[NSString alloc]
                         initWithBytes:(bytes + ptoken->index + 1)
                         length:ptoken->length - 2
                         encoding: NSUTF8StringEncoding];
        ptoken->type = TokenType_Value_String;
        return;
    }
    
    if (ptoken->length == 4) {
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
        
        return;
    }
    
    if (ptoken->length == 5) {
        if (    (bytes[ptoken->index + 0] == 'f' || bytes[ptoken->index + 0] == 'F')
            && (bytes[ptoken->index + 1] == 'a' || bytes[ptoken->index + 1] == 'A')
            && (bytes[ptoken->index + 2] == 'l' || bytes[ptoken->index + 2] == 'L')
            && (bytes[ptoken->index + 3] == 's' || bytes[ptoken->index + 3] == 'S')
            && (bytes[ptoken->index + 4] == 'e' || bytes[ptoken->index + 4] == 'E'))
        {
            ptoken->value = [NSNumber numberWithBool:false];
            ptoken->type = TokenType_Value_Bool;
        }
        return;
    }
    
    // parse double
    
    NSNumber * number = tryMakeDouble(ptoken->index, ptoken->length, bytes);
    if (number != nil) {
        ptoken->value = number;
        ptoken->type = TokenType_Value_Number;
        return;
    }
    
    NSLog(@"Invalid token at byte index: %d", ptoken->index);
    exit(EXIT_FAILURE);
}

- (void) parseCollections:(__unsafe_unretained NSData *) data {
    
    const char* const bytes = data.bytes;
    
    // index == length, index points to a position after the last element
    
    if (tokens.index == 0) {
        result = NSNull.null;
        return;
    }
    
    if (tokens.index == 1) {
        OCToken * ptoken = ocarray_get(&tokens, 0);
        TokenType type = ptoken->type;
        parseTokenValue(ptoken, bytes);
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
        parseTokenValue(ptoken, bytes);
        TokenType type = ptoken->type;
        switch (type) {
            case TokenType_Unresolved: {
                NSLog(@"Token type unresolved: %@", ptoken->value);
                exit(EXIT_FAILURE);
                break;
            }
            case TokenType_MapOpen: {
                [stack addObject: [[NSMutableDictionary alloc] init]];
                break;
            }
            case TokenType_MapClose: {
                popStack(self);
                break;
            }
            case TokenType_ArrayOpen: {
                [stack addObject: [[NSMutableArray alloc] init]];
                break;
            }
            case TokenType_ArrayClose: {
                popStack(self);
                break;
            }
            case TokenType_KeyValueDelimiter: {
#ifdef DEBUG
                // validations only
                if (key == nil) {
                    NSLog(@"Found the key-value separator without a key being set previously");
                    exit(EXIT_FAILURE);
                }
#endif
                break;
            }
            case TokenType_ElementDelimiter:{
#ifdef DEBUG
                if (key != nil) { // will crash if wrong type
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
                consumeNewValue(self, current, ptoken->value);
                break;
            }
        }
    }
}

void popStack (__unsafe_unretained JsonParserObjcC * parser) {
    id current = parser->stack.lastObject;
    [parser->stack removeLastObject];
    id parent = parser->stack.lastObject;
    if (parent != nil) {
        consumeNewValue(parser, parent, current);
    }
    else {
#ifdef DEBUG
        if (parser->key != nil) {
            NSLog(@"Completing a collection, but the map is not complete");
            exit(EXIT_FAILURE);
        }
#endif
        parser->result = current;
    }
}

void consumeNewValue(__unsafe_unretained JsonParserObjcC * parser,
                     __unsafe_unretained id collection,
                     __unsafe_unretained id newValue) {
    
    if ([collection isKindOfClass: NSMutableDictionary.class]) {
        NSMutableDictionary* col = collection;
        if (parser->key == nil) {
            if (![newValue isKindOfClass: NSString.class]) {
                NSLog(@"Expected a map key, but got: %@", newValue);
                exit(EXIT_FAILURE);
            }
            parser->key = newValue;
        }
        else {
            col[parser->key] = newValue;
            parser->key = nil;
        }
    }
    else if ([collection isKindOfClass: NSMutableArray.class]) {
        NSMutableArray* col = collection;
        [col addObject: newValue];
    }
    
}

@end
