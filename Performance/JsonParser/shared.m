//
//  shared.m
//  Performance
//
//  Created by Ivan Milinkovic on 14.9.23..
//

#import <Foundation/Foundation.h>
#import "Shared.h"

NSNumber * tryMakeDouble(int startIndex, int length, const char * bytes) {
    
//    double res = strtod(bytes + startIndex, NULL);
//    if (res == 0.0) {
//        printf("%f", res);
//    }
//    return @(res);

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
        double tens = 1.0;
        
        for (int k=j; k<endIndex; k++) {
            char byte = bytes[k];
            if (byte < '0' || byte > '9') {
                return nil;
            }
            int digit = byte - '0';
            tens *= 10;
            decimalPart += digit / tens;
        }
        
        num += decimalPart;
    }
    
    if (hasMinus) {
        num *= -1;
    }
    
    return [NSNumber numberWithDouble:num];
}
