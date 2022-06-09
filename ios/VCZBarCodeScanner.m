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

// ZXingObjC/core/ZXBarcodeFormat.h
static NSString *createStringFromZXBarcodeFormat(ZXBarcodeFormat format) {
  switch (format) {
  /** Aztec 2D barcode format. */
  case kBarcodeFormatAztec:
    return @"Aztec";

  /** CODABAR 1D format. */
  case kBarcodeFormatCodabar:
    return @"Codabar";

  /** Code 39 1D format. */
  case kBarcodeFormatCode39:
    return @"Code39";

  /** Code 93 1D format. */
  case kBarcodeFormatCode93:
    return @"Code93";

  /** Code 128 1D format. */
  case kBarcodeFormatCode128:
    return @"Code128";

  /** Data Matrix 2D barcode format. */
  case kBarcodeFormatDataMatrix:
    return @"DataMatrix";

  /** EAN-8 1D format. */
  case kBarcodeFormatEan8:
    return @"Ean8";

  /** EAN-13 1D format. */
  case kBarcodeFormatEan13:
    return @"Ean13";

  /** ITF (Interleaved Two of Five) 1D format. */
  case kBarcodeFormatITF:
    return @"ITF";

  /** MaxiCode 2D barcode format. */
  case kBarcodeFormatMaxiCode:
    return @"MaxiCode";

  /** PDF417 format. */
  case kBarcodeFormatPDF417:
    return @"PDF417";

  /** QR Code 2D barcode format. */
  case kBarcodeFormatQRCode:
    return @"QRCode";

  /** RSS 14 */
  case kBarcodeFormatRSS14:
    return @"RSS14";

  /** RSS EXPANDED */
  case kBarcodeFormatRSSExpanded:
    return @"RSSExpanded";

  /** UPC-A 1D format. */
  case kBarcodeFormatUPCA:
    return @"UPCA";

  /** UPC-E 1D format. */
  case kBarcodeFormatUPCE:
    return @"UPCE";

  /** UPC/EAN extension format. Not a stand-alone format. */
  case kBarcodeFormatUPCEANExtension:
    return @"UPCEANExtension";
  };
}

// ZXingObjC/core/ZXResultMetadataType.h
static NSString *
createStringFromZXResultMetadataType(ZXResultMetadataType type) {
  switch (type) {
  /**
   * Unspecified, application-specific metadata. Maps to an unspecified
   * NSObject.
   */
  case kResultMetadataTypeOther:
    return @"other";

  /**
   * Denotes the likely approximate orientation of the barcode in the image.
   * This value is given as degrees rotated clockwise from the normal, upright
   * orientation. For example a 1D barcode which was found by reading
   * top-to-bottom would be said to have orientation "90". This key maps to an
   * integer whose value is in the range [0,360).
   */
  case kResultMetadataTypeOrientation:
    return @"orientation";

  /**
   * 2D barcode formats typically encode text, but allow for a sort of 'byte
   * mode' which is sometimes used to encode binary data. While ZXResult makes
   * available the complete raw bytes in the barcode for these formats, it does
   * not offer the bytes from the byte segments alone.
   *
   * This maps to an array of byte arrays corresponding to the
   * raw bytes in the byte segments in the barcode, in order.
   */
  case kResultMetadataTypeByteSegments:
    return @"byteSegments";

  /**
   * Error correction level used, if applicable. The value type depends on the
   * format, but is typically a String.
   */
  case kResultMetadataTypeErrorCorrectionLevel:
    return @"errorCorrectionLevel";

  /**
   * For some periodicals, indicates the issue number as an integer.
   */
  case kResultMetadataTypeIssueNumber:
    return @"issueNumber";

  /**
   * For some products, indicates the suggested retail price in the barcode as a
   * formatted NSString.
   */
  case kResultMetadataTypeSuggestedPrice:
    return @"suggestedPrice";

  /**
   * For some products, the possible country of manufacture as NSString denoting
   * the ISO country code. Some map to multiple possible countries, like
   * "US/CA".
   */
  case kResultMetadataTypePossibleCountry:
    return @"possibleCountry";

  /**
   * For some products, the extension text
   */
  case kResultMetadataTypeUPCEANExtension:
    return @"UPCEANExtension";

  /**
   * PDF417-specific metadata
   */
  case kResultMetadataTypePDF417ExtraMetadata:
    return @"PDF417ExtraMetadata";

  /**
   * If the code format supports structured append and the current scanned code
   * is part of one then the sequence number is given with it.
   */
  case kResultMetadataTypeStructuredAppendSequence:
    return @"structuredAppendSequence";

    /**
     * If the code format supports structured append and the current scanned
     * code is part of one then the parity is given with it.
     */
  case kResultMetadataTypeStructuredAppendParity:
    return @"structuredAppendParity";
  default:
    return [@(type) stringValue];
  }
}

static inline id convertZXResultPoint(ZXResultPoint *point) {
  return @{@"x" : @(point.x), @"y" : @(point.y)};
}

// To Base64
/**
 * Converts a `ZXByteArray` object to React Native compatible object.
 *
 * This function converts a `ZXByteArray` object to an array containing
 * integers.
 */
static id convertZXByteArray(ZXByteArray *byteSegment) {
  // Basically, most application converts raw bytes into base64 string,
  // but we converts it to an array containing integers.
  // We chose this approach because a byte segment is relatively small
  // in the most cases.
  NSMutableArray *bytes =
      [[NSMutableArray alloc] initWithCapacity:byteSegment.length];

  for (int i = 0; i < byteSegment.length; i++) {
    [bytes addObject:@(byteSegment.array[i])];
  }

  return bytes;
}

// QRCode metadata value to React native value.
static id convertMetadataValue(id value) {
  if ([value isKindOfClass:[ZXResultPoint class]]) {
    return convertZXResultPoint(value);
  } else if ([value isKindOfClass:[ZXByteArray class]]) {
    return convertZXByteArray(value);
  } else if ([value isKindOfClass:[NSArray class]]) {
    NSMutableArray *newValues =
        [NSMutableArray arrayWithCapacity:[(NSArray *)value count]];

    for (id v in value) {
      [newValues addObject:convertMetadataValue(v)];
    }

    return newValues;
  }

  return value;
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
    return [NSNull null];
  }

  const size_t videoFrameImageWidth = CGImageGetWidth(videoFrameImage);
  const size_t videoFrameImageHeight = CGImageGetHeight(videoFrameImage);

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
    // The barcode format, such as a QR code or UPC-A
    const ZXBarcodeFormat format = result.barcodeFormat;

    // We have to convert keys in resultMetadata to string due to
    // VisionCamera limitation.
    NSMutableDictionary *meradata = nil;

    if (result.resultMetadata != nil) {
      meradata = [@{} mutableCopy];

      for (id key in result.resultMetadata) {
        id value = result.resultMetadata[key];
        NSString *stringKey =
            [key isKindOfClass:[NSNumber class]]
                ? createStringFromZXResultMetadataType([key intValue])
                : [key description];

        // NSLog(@"metadata: %@ = %@", stringKey, value);
        meradata[stringKey] = convertMetadataValue(value);
      }
    }

    // Convert points
    NSMutableArray *points = nil;
    if (result.resultPoints) {
      points = [NSMutableArray arrayWithCapacity:4];

      for (ZXResultPoint *pt in result.resultPoints) {
        [points addObject:convertZXResultPoint(pt)];
      }
    }

    return @{
      @"width" : @(videoFrameImageWidth),
      @"height" : @(videoFrameImageHeight),
      @"code" : @{
        // raw text encoded by the barcode
        @"text" : result.text,
        // representing the format of the barcode that was decoded
        @"format" : createStringFromZXBarcodeFormat(format),
        // points related to the barcode in the image. These are typically
        // points identifying finder patterns or the corners of the barcode. The
        // exact meaning is specific to the type of barcode that was decoded.
        @"points" : points ? points : [NSNull null],
        // mapping ZXResultMetadataType keys to values. May be nil. This
        // contains
        // optional metadata about what was detected about the barcode, like
        // orientation.
        @"metadata" : meradata ? meradata : [NSNull null],
      }
    };

  } else if (error != nil) {
    // Use error to determine why we didn't get a result, such as a barcode
    // not being found, an invalid checksum, or a format inconsistency.
    if ([error.domain isEqualToString:ZXErrorDomain] &&
        error.code == ZXNotFoundError) {
      // QR code not found
    } else {
      NSLog(@"Error = %@", error.description);
    }
  }

  return [NSNull null];
}
@end
