#import <Foundation/Foundation.h>
#import <VisionCamera/Frame.h>

NS_ASSUME_NONNULL_BEGIN

@interface VCZBarcodeScanner : NSObject

- (id)detect:(Frame *)frame args:(NSArray *)args;

@end

NS_ASSUME_NONNULL_END
