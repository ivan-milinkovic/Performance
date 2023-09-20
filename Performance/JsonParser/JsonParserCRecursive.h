//
//  JsonParserNestedLoops.h
//  Performance
//
//  Created by Ivan Milinkovic on 17.9.23..
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JsonParserCRecursive : NSObject

- (id) parse:(NSData *) data NS_SWIFT_NAME(parse(data:));

@end

NS_ASSUME_NONNULL_END
