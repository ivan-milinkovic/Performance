#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JsonParserObjc : NSObject

- (id) parse:(NSData *) data NS_SWIFT_NAME(parse(data:));

@end

NS_ASSUME_NONNULL_END
