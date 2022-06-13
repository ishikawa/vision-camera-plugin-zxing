#import "VCZMultipleBarcodeReader.h"

@implementation VCZMultipleBarcodeReader

- (id)initWithReader:(id<ZXReader>)reader {
  if (self = [super init]) {
    _reader = reader;
  }
  return self;
}

- (NSArray *)decodeMultiple:(ZXBinaryBitmap *)image error:(NSError **)error {
  return [self decodeMultiple:image hints:nil error:error];
}

- (NSArray *)decodeMultiple:(ZXBinaryBitmap *)image
                      hints:(ZXDecodeHints *)hints
                      error:(NSError **)error {
  ZXResult *result = [self.reader decode:image hints:hints error:error];

  return (result != nil) ?  @[ result ] : @[];
}

@end
