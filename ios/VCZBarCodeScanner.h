#import <Foundation/Foundation.h>
#import <VisionCamera/Frame.h>

NS_ASSUME_NONNULL_BEGIN

@interface VCZBarcodeScanner : NSObject

- (id)detect:(Frame *)frame
     formats:(NSArray<NSString *> *)formats
     options:(NSDictionary *)options;

@end

NS_ASSUME_NONNULL_END
