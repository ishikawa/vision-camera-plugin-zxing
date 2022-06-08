#import "VCZBarCodeScanner.h"
#import <VideoToolbox/VideoToolbox.h>
#import <ZXingObjC/ZXingObjC.h>

static CGFloat
rotationDegreesForUIImageOrientation(UIImageOrientation orientation) {
  switch (orientation) {
  case UIImageOrientationUp:
  case UIImageOrientationUpMirrored:
    return 0.0f;
  case UIImageOrientationDown:
  case UIImageOrientationDownMirrored:
    return 180.0f;
  case UIImageOrientationLeft:
  case UIImageOrientationLeftMirrored:
    return 90.0f;
  case UIImageOrientationRight:
  case UIImageOrientationRightMirrored:
    return 270.0f;
  }
}

static CGImageRef createRotatedImage(CGImageRef original, CGFloat degrees) {
  if (degrees == 0.0f) {
    CGImageRetain(original);
    return original;
  } else {
    double radians = degrees * M_PI / 180;

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
    radians = -1 * radians;
#endif

    size_t _width = CGImageGetWidth(original);
    size_t _height = CGImageGetHeight(original);

    CGRect imgRect = CGRectMake(0, 0, _width, _height);
    CGAffineTransform __transform = CGAffineTransformMakeRotation(radians);
    CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, __transform);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
        NULL, rotatedRect.size.width, rotatedRect.size.height,
        CGImageGetBitsPerComponent(original), 0, colorSpace,
        kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedFirst);
    CGContextSetAllowsAntialiasing(context, FALSE);
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGColorSpaceRelease(colorSpace);

    CGContextTranslateCTM(context, +(rotatedRect.size.width / 2),
                          +(rotatedRect.size.height / 2));
    CGContextRotateCTM(context, radians);

    CGContextDrawImage(context,
                       CGRectMake(-imgRect.size.width / 2,
                                  -imgRect.size.height / 2, imgRect.size.width,
                                  imgRect.size.height),
                       original);

    CGImageRef rotatedImage = CGBitmapContextCreateImage(context);
    CFRelease(context);

    return rotatedImage;
  }
}

@interface VCZBarCodeScanner ()

@property(nonatomic, readonly) ZXMultiFormatReader *reader;

@property(nonatomic) NSUInteger nScanned;

@end

@implementation VCZBarCodeScanner

- (instancetype)init {
  if (self = [super init]) {
    // TODO: Pass hints via arguments?
    _reader = [ZXMultiFormatReader reader];

    // There are a number of hints we can give to the reader, including
    // possible formats, allowed lengths, and the string encoding.
    //
    // the state set up by calling setHints() previously
    // Continuous scan clients will get a large speed increase by setting
    // the state previously.
    _reader.hints = [ZXDecodeHints hints];
  }
  return self;
}

- (id)scan:(Frame *)frame args:(NSArray *)args {
  const UIImageOrientation orientation = frame.orientation;

  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(frame.buffer);
  CGImageRef videoFrameImage = NULL;

  if (VTCreateCGImageFromCVPixelBuffer(pixelBuffer, NULL, &videoFrameImage) !=
      errSecSuccess) {
    return @[];
  }

  // --- Correct CGImage to match the desired orientation.
  const CGFloat captureRotation =
      rotationDegreesForUIImageOrientation(orientation);

  // TODO: If scanRect is set, crop the current image to include only the
  // desired rect

  // Rotate image if needed.
  CGImageRef rotatedImage =
      createRotatedImage(videoFrameImage, captureRotation);

  _nScanned++;

  // DEBUG: Get JPEG representation for debug.
  /*
  if (nScanned % 30 == 0) {
    UIImage *img = [UIImage imageWithCGImage:rotatedImage
                                       scale:1.0f
                                 orientation:orientation];
    NSData *bitmapRep = UIImageJPEGRepresentation(img, 0.3f);
    NSString *base64JPEG = [bitmapRep base64EncodedStringWithOptions:0];

    return @[ @{
      @"orientation" : @(orientation),
      @"captureRotation" : @(captureRotation),
      @"base64JPEG" : base64JPEG
    } ];
  }
  */

  ZXCGImageLuminanceSource *source =
      [[ZXCGImageLuminanceSource alloc] initWithCGImage:rotatedImage];
  ZXHybridBinarizer *binarizer =
      [[ZXHybridBinarizer alloc] initWithSource:source];
  ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];

  NSError *error = nil;
  ZXResult *result = [self.reader decodeWithState:bitmap error:&error];

  CGImageRelease(videoFrameImage);
  CGImageRelease(rotatedImage);

  if (result) {
    // The coded result as a string. The raw data can be accessed with
    // result.rawBytes and result.length.
    NSString *contents = result.text;

    // The barcode format, such as a QR code or UPC-A
    const ZXBarcodeFormat format = result.barcodeFormat;

    NSLog(@"QR code = %@ (format = %d)", contents, format);

    return @[ @{
      @"contents" : contents,
      @"format" : @(format),
    } ];

  } else if (error != nil) {
    if ([error.domain isEqualToString:ZXErrorDomain] &&
        error.code == ZXNotFoundError) {
      // QR code not found
    } else {
      // Use error to determine why we didn't get a result, such as a barcode
      // not being found, an invalid checksum, or a format inconsistency.
      NSLog(@"Error = %@", error.description);
    }
  }

  return @[];
}
@end
