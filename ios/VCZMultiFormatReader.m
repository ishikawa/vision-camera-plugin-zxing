#import "VCZMultiFormatReader.h"

@implementation VCZMultiFormatReader

- (id)initWithReader:(ZXMultiFormatReader *)reader {
  if (self = [super init]) {
    _reader = reader;
  }
  return self;
}

- (ZXResult *)decode:(ZXBinaryBitmap *)image error:(NSError **)error {
  return [self.reader decodeWithState:image error:error];
}

- (ZXResult *)decode:(ZXBinaryBitmap *)image
               hints:(ZXDecodeHints *)hints
               error:(NSError **)error {
  return [self.reader decodeWithState:image error:error];
}

- (void)reset {
  [self.reader reset];
}
@end
