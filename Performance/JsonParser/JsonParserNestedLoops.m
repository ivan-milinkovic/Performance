//
//  JsonParserNestedLoops.m
//  Performance
//
//  Created by Ivan Milinkovic on 17.9.23..
//

#import "JsonParserNestedLoops.h"
#import "Shared.h"

#define printc(c) printf("%c\n", c);
//#define printc(c)

#define is_index_outside (*index >= len)
#define inc_index (*index)++

@implementation JsonParserNestedLoops

- (id) parse:(NSData *) data NS_SWIFT_NAME(parse(data:)) {
    const char * bytes = data.bytes;
    int len = (int) data.length;
    int index = 0;
    char ** error = calloc(100, 1);
    id result = root(&index, bytes, len, error);
    if (*error) {
        printf("%s\n", *error);
        return nil;
    }
    free(error);
    return result;
}

id root(int* index, const char * bytes, int len, char ** error) {
    id res = nil;
    skipWhitespace(index, bytes, len);
    char c = bytes[*index];
    printc(c)
    switch (c) {
        case 'n': {
            res = parseNull(index, bytes, len, error);
            break;
        }
        case 't': {
            res = parseTrue(index, bytes, len, error);
            break;
        }
        case 'f': {
            res = parseFalse(index, bytes, len, error);
            break;
        }
        case '"': {
            res = parseString(index, bytes, len, error);
            break;
        }
        case '{': {
            res = parseMap(index, bytes, len, error);
            break;
        }
        default: {
            snprintf(*error, 100, "Unexpected character at %d", *index);
            return nil;
        }
    }
    
    // check there are no more elements after the root
    skipWhitespace(index, bytes, len);
    if (is_index_outside) {
        return res;
    } else {
        *error = "Cannot have elements after root element";
        return nil;
    }
    
    return res;
}

id innerParse(int* index, const char * bytes, int len, char ** error) {
    if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Element is incomplete")) {
        return nil;
    }
    id res = nil;
    char c = bytes[*index];
    switch (c) {
        case 'n': {
            res = parseNull(index, bytes, len, error);
            break;
        }
        case 't': {
            res = parseTrue(index, bytes, len, error);
            break;
        }
        case 'f': {
            res = parseFalse(index, bytes, len, error);
            break;
        }
        case '"': {
            res = parseString(index, bytes, len, error);
            break;
        }
        case '{': {
            res = parseMap(index, bytes, len, error);
            break;
        }
        case '}': {
            return nil; // allow parent map to close itself
        }
    }
    
    return res;
}

bool validate_index(int* index, int len, char ** error, char * error_message) {
    if (is_index_outside) {
        *error = error_message;
        return false;
    }
    return true;
}

bool inc_validate_index(int* index, int len, char ** error, char * error_message) {
    inc_index;
    if (is_index_outside) {
        *error = error_message;
        return false;
    }
    return true;
}

bool skip_whitespace_and_validate_index(int* index, const char * bytes, int len, char ** error, char * error_message) {
    skipWhitespace(index, bytes, len);
    if (is_index_outside) {
        *error = error_message;
        return false;
    }
    return true;
}

NSNull* parseNull(int* index, const char * bytes, int len, char ** error) {
    if ((len - *index) < 4) {
        *error = "parseNull: invalid length";
        return nil;
    }
    if (0 == memcmp(bytes + *index, "null", 4)) {
        (*index) += 4;
        return NSNull.null;
    }
    return nil;
}

NSNumber* parseTrue(int* index, const char * bytes, int len, char ** error) {
    if ((len - *index) < 4) {
        *error = "parseTrue: invalid length";
        return nil;
    }
    if (0 == memcmp(bytes + *index, "true", 4)) {
        (*index) += 4;
        return @(true);
    }
    return nil;
}

NSNumber* parseFalse(int* index, const char * bytes, int len, char ** error) {
    if ((len - *index) < 5) {
        *error = "parseFalse: invalid length";
        return nil;
    }
    if (0 == memcmp(bytes + *index, "false", 5)) {
        (*index) += 5;
        return @(false);
    }
    return nil;
}

NSString * parseString(int* index, const char * bytes, int len, char ** error) {
    inc_validate_index(index, len, error, "String malformed");
    bool isEscaping = false;
    NSMutableString * str = [[NSMutableString alloc] init];
    while((*index) < len) {
        char c = bytes[*index];
        if (c == '\\') {
            isEscaping = true;
        }
        if (c == '"' && !isEscaping) {
            break;
        }
        
        [str appendFormat: @"%c", c];
        inc_index;
    }
    inc_index;
    return str;
}

NSDictionary * parseMap(int* index, const char * bytes, int len, char ** error) {
    
    NSMutableDictionary * map = [[NSMutableDictionary alloc] init];
    inc_index;
    if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Map is incomplete")) {
        return nil;
    }
    
    // check if map is empty
    char c = bytes[*index];
    printc(c)
    if (c == '}') {
        inc_index;
        return map;
    }
    
    // parse key
    if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Map is incomplete")) {
        return nil;
    }
    
    bool spin = true;
    while (spin) {
        NSString * key = parseString(index, bytes, len, error);
        if (*error) { return nil; }
        
        // search for key value delimiter ":"
        if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Map is incomplete")) {
            return nil;
        }
        
        c = bytes[*index];
        if (c != ':') {
            *error = "Map expects a \":\" delimiter after the key";
            return nil;
        }
        inc_index;
        
        // parse value
        id value = innerParse(index, bytes, len, error);
        if (*error) { return nil; }
        
        if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Map is incomplete")) {
            return nil;
        }
        
        [map setValue:value forKey:key];
        
        // continue or not
        c = bytes[*index];
        
        switch (c) {
            case ',':
                continue; // parse more key-value pairs
            case '}':
                spin = false; // close the map
                break;
            default:
                *error = "Map expects an element delimiter \",\" or a closing curly brace \"}\"";
                return nil;
        }
        
        inc_index;
    }
    
    return map;
}



void skipWhitespace(int* index, const char * bytes, int len) {
    while(isWhitespace(bytes[*index]) && inc_index < len) { }
}

@end
