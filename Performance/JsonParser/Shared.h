
#ifndef Shared_h
#define Shared_h

#define CHAR_SPACE ' '
#define CHAR_NEWLINE '\n'
#define CHAR_CARRIAGE '\r'
#define CHAR_TAB '\t'
#define CHAR_STRING_DELIMITER '"'
#define CHAR_STRING_ESCAPE '\\'
#define CHAR_MAP_OPEN '{'
#define CHAR_MAP_CLOSE '}'
#define CHAR_ARRAY_OPEN '['
#define CHAR_ARRAY_CLOSE ']'
#define CHAR_KEY_VALUE_DELIMITER ':'
#define CHAR_ELEMENT_DELIMITER ','

typedef NS_ENUM(char, TokenType) {
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

@class NSNumber;
NSNumber * tryMakeDouble(int startIndex, int length, const char * bytes);

#endif /* Shared_h */
