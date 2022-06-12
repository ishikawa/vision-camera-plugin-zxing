#import <Foundation/Foundation.h>
#import <ZXingObjC/ZXingObjC.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * This class wraps ZXMultiFormatReader instance and it always invoke
 * `decodeWithState:error` method to decode an image to gain performance.
 */
@interface VCZMultiFormatReader : NSObject <ZXReader>

@property(nonatomic, readonly, strong) ZXMultiFormatReader *reader;

- (id)initWithReader:(ZXMultiFormatReader *)reader;

@end

NS_ASSUME_NONNULL_END
