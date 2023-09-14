#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JsonParserObjcC : NSObject

- (id) parse:(NSData *) data NS_SWIFT_NAME(parse(data:));
- (id) parseString:(NSString *) string NS_SWIFT_NAME(parse(jsonString:));

@end

NS_ASSUME_NONNULL_END
