//
//  Allocations.m
//  Performance
//
//  Created by Ivan Milinkovic on 17.9.23..
//

#import "ObjcAllocations.h"

@implementation ObjcAllocations

+ (NSArray *) allocate {
    NSMutableArray * array = [NSMutableArray new];
    for(int i = 0; i < 10000; i++) {
        NSMutableDictionary * d = [NSMutableDictionary new];
        d[@"lat1"] = @123.0;
        d[@"lon"] = @234;
        d[@"lat2"] = @123;
        d[@"lon2"] = @234;
        [array addObject: d];
    }
    return array;
}

@end
