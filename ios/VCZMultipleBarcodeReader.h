#import <Foundation/Foundation.h>
#import <ZXingObjC/ZXingObjC.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * This class wraps ZXReader instance and it always return
 * the result as an array containing one barcode to confirm
 * the `ZXMultipleBarcodeReader` protocol.
 */
@interface VCZMultipleBarcodeReader : NSObject <ZXMultipleBarcodeReader>

@property(nonatomic, readonly, strong) id<ZXReader> reader;

- (id)initWithReader:(id<ZXReader>)reader;

@end

NS_ASSUME_NONNULL_END
