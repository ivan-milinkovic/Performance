//
//  JsonParserNestedLoops.m
//  Performance
//
//  Created by Ivan Milinkovic on 17.9.23..
//

#import "JsonParserCNestedLoops.h"
#import "Shared.h"

#define printc(c) printf("%c\n", c);
//#define printc(c)

#define is_index_outside (*index >= len)
#define inc_index (*index)++

@implementation JsonParserCNestedLoops

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
        case '[': {
            res = parseArray(index, bytes, len, error);
            break;
        }
        default: {
            if (is_num_char(c)) {
                res = parseNumber(index, bytes, len, error);
                break;
            }
            
//            *error = "Unexpected character at ______________";
//            snprintf(*error, 100, "Unexpected character at %d", *index); // figure out the crash
            
            *error =  "Unexpected character";
            return nil;
        }
    }
    
    if (*error) {
        return nil;
    }
    
    // check there are no more elements after the root
    skipWhitespace(index, bytes, len);
    if (!is_index_outside) {
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
            
        default: {
            if (is_num_char(c)) {
                res = parseNumber(index, bytes, len, error);
                break;
            }
            
            *error = "innerParse: unexpected character";
            return nil;
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

void skipWhitespace(int* index, const char * bytes, int len) {
    while(isWhitespace(bytes[*index]) && inc_index < len) { }
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
    int i_start = *index;
    while((*index) < len) {
        char c = bytes[*index];
        if (c == '\\') {
            isEscaping = true;
        }
        if (c == '"' && !isEscaping) {
            break;
        }
        
        inc_index;
    }
    
    int str_len = *index - i_start;
    NSString * str = [[NSString alloc] initWithBytes:(bytes + i_start) length:str_len encoding:NSUTF8StringEncoding];
    inc_index;
    return str;
}

bool is_num_char(char c) {
    return c == '+' || c == '-' || c == '.'
        || c == '0' || c == '1' || c == '2' || c == '3' || c == '4'
        || c == '5' || c == '6' || c == '7' || c == '8' || c == '9';
}

NSNumber * parseNumber(int* index, const char * bytes, int len, char ** error) {
    int i_start = *index;
    int num_len = 0;
    
    while (1) {
        char c = bytes[*index];
        if (!is_num_char(c)) {
            break;
        }
        num_len++;
        inc_index;
    }
    
    if (num_len == 0) {
        return nil;
    }
    
    return tryMakeDouble(i_start, num_len, bytes);
}

NSDictionary * parseMap(int* index, const char * bytes, int len, char ** error) {
    
    NSMutableDictionary * map = [[NSMutableDictionary alloc] init];
    inc_index;
    if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Map is incomplete")) {
        return nil;
    }
    
    // check if map is empty
    char c = bytes[*index];
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
        if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Map is incomplete")) {
            return nil;
        }
        
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
        if (value == nil) {
            *error = "Map value is missing";
            return nil;
        }
        [map setValue:value forKey:key];
        
        // continue or not
        if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Map is incomplete")) {
            return nil;
        }
        c = bytes[*index];
        
        switch (c) {
            case ',':
                inc_index;
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

NSArray * parseArray(int* index, const char * bytes, int len, char ** error) {
    // skip the opening bracket [ and the whitespace after it
    inc_index;
    if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Array is incomplete")) {
        return nil;
    }
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    
    char c = bytes[*index];
    if (c == ']') {
        inc_index;
        return array;
    }
    
    bool spin = true;
    while(spin) {
        if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Array is incomplete")) {
            return nil;
        }
        
        id value = innerParse(index, bytes, len, error);
        if (value == nil) {
            *error = "Array value is missing";
            return nil;
        }
        
        [array addObject: value];
        
        if (!skip_whitespace_and_validate_index(index, bytes, len, error, "Array is incomplete")) {
            return nil;
        }
        
        // continue or not
        c = bytes[*index];
        switch (c) {
            case ',':
                inc_index;
                continue; // parse more key-value pairs
            case ']':
                inc_index;
                spin = false; // close the map
                break;
            default:
                *error = "Array expects an element delimiter \",\" or a closing square bracket \"]\"";
                return nil;
        }
    }
    
    return array;
}


@end
