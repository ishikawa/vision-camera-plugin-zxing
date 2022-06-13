#import "VCZBarcodeScanner.h"
#import "VCZMultiFormatReader.h"
#import "VCZMultipleBarcodeReader.h"
#import <VideoToolbox/VideoToolbox.h>
#import <ZXingObjC/ZXingObjC.h>

// If the decoding formats contain "QRCode" or "PDF417" only, we can
// use specific implementation.
// - ZXQRCodeMultiReader
// - ZXPDF417Reader
#define USE_BARCODE_SPECIFIC_MULTIPLE_READER 1

// ZXingObjC/core/ZXBarcodeFormat.h
static ZXBarcodeFormat barcodeFormatFromString(NSString *format) {
  /** Aztec 2D barcode format. */
  if ([format isEqualToString:@"Aztec"]) {
    return kBarcodeFormatAztec;
  }

  /** CODABAR 1D format. */
  if ([format isEqualToString:@"Codabar"]) {
    return kBarcodeFormatCodabar;
  }

  /** Code 39 1D format. */
  if ([format isEqualToString:@"Code39"]) {
    return kBarcodeFormatCode39;
  }

  /** Code 93 1D format. */
  if ([format isEqualToString:@"Code93"]) {
    return kBarcodeFormatCode93;
  }

  /** Code 128 1D format. */
  if ([format isEqualToString:@"Code128"]) {
    return kBarcodeFormatCode128;
  }

  /** Data Matrix 2D barcode format. */
  if ([format isEqualToString:@"DataMatrix"]) {
    return kBarcodeFormatDataMatrix;
  }

  /** EAN-8 1D format. */
  if ([format isEqualToString:@"Ean8"]) {
    return kBarcodeFormatEan8;
  }

  /** EAN-13 1D format. */
  if ([format isEqualToString:@"Ean13"]) {
    return kBarcodeFormatEan13;
  }

  /** ITF (Interleaved Two of Five) 1D format. */
  if ([format isEqualToString:@"ITF"]) {
    return kBarcodeFormatITF;
  }

  /** MaxiCode 2D barcode format. */
  if ([format isEqualToString:@"MaxiCode"]) {
    return kBarcodeFormatMaxiCode;
  }

  /** PDF417 format. */
  if ([format isEqualToString:@"PDF417"]) {
    return kBarcodeFormatPDF417;
  }

  /** QR Code 2D barcode format. */
  if ([format isEqualToString:@"QRCode"]) {
    return kBarcodeFormatQRCode;
  }

  /** RSS 14 */
  if ([format isEqualToString:@"RSS14"]) {
    return kBarcodeFormatRSS14;
  }

  /** RSS EXPANDED */
  if ([format isEqualToString:@"RSSExpanded"]) {
    return kBarcodeFormatRSSExpanded;
  }

  /** UPC-A 1D format. */
  if ([format isEqualToString:@"UPCA"]) {
    return kBarcodeFormatUPCA;
  }

  /** UPC-E 1D format. */
  if ([format isEqualToString:@"UPCE"]) {
    return kBarcodeFormatUPCE;
  }

  /** UPC/EAN extension format. Not a stand-alone format. */
  if ([format isEqualToString:@"UPCEANExtension"]) {
    return kBarcodeFormatUPCEANExtension;
  }

  // Unknown
  return 0;
};

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

/**
 * Converts a `ZXByteArray` object to React Native compatible object.
 * This function encodes a `ZXByteArray` object to base64 string.
 */
static id convertZXByteArray(ZXByteArray *byteSegment) {
  // An element of byteSegments can be too large to represent as
  // JS number array, so we encode it to base64 string.
  NSData *data = [NSData dataWithBytes:byteSegment.array
                                length:byteSegment.length];
  return [data base64EncodedStringWithOptions:0];
}

// QRCode metadata value to React native value.
static id convertMetadataValue(id value) {
  if ([value isKindOfClass:[ZXByteArray class]]) {
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

@interface VCZBarcodeScanner ()

@property(nonatomic, readonly) id<ZXMultipleBarcodeReader> reader;

@property(nonatomic, readonly) ZXDecodeHints *hints;

// We have to hold the reference to delegate
@property(nonatomic, readonly) id<ZXReader> delegateReader;

@property(nonatomic) NSUInteger nScanned;

@end

@implementation VCZBarcodeScanner

+ (ZXDecodeHints *)hintsWithFormats:(NSArray<NSString *> *)formats
                            options:(NSDictionary *)options {
  // There are a number of hints we can give to the reader, including
  // possible formats, allowed lengths, and the string encoding.

  ZXDecodeHints *hints = [ZXDecodeHints hints];

  // formats
  for (NSString *formatValue in formats) {
    const ZXBarcodeFormat format = barcodeFormatFromString(formatValue);
    [hints addPossibleFormat:format];
  }

  // tryHarder
  hints.tryHarder = [options[@"accurate"] boolValue];

  return hints;
}

+ (id<ZXReader>)createMultiFormatReaderWithHints:(ZXDecodeHints *)hints {
  ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
  reader.hints = hints;
  return [[VCZMultiFormatReader alloc] initWithReader:reader];
}

+ (id<ZXMultipleBarcodeReader>)
    createWrappedReaderWithDelegate:(id<ZXReader>)delegate
                            formats:(NSArray<NSString *> *)formats
                            options:(NSDictionary *)options {
  id<ZXReader> reader = delegate;

  // readByQuadrant
  if ([options[@"readByQuadrant"] boolValue]) {
    reader = [[ZXByQuadrantReader alloc] initWithDelegate:reader];
  }

  // readMultiple
  if ([options[@"readMultiple"] boolValue]) {

#if USE_BARCODE_SPECIFIC_MULTIPLE_READER
    if (formats.count == 1 && [formats[0] isEqualToString:@"QRCode"]) {
      return [[ZXQRCodeMultiReader alloc] init];
    } else if (formats.count == 1 && [formats[0] isEqualToString:@"PDF417"]) {
      return [[ZXPDF417Reader alloc] init];
    }
#endif

    return [[ZXGenericMultipleBarcodeReader alloc] initWithDelegate:reader];
  } else {
    return [[VCZMultipleBarcodeReader alloc] initWithReader:reader];
  }
}

- (id)detect:(Frame *)frame
     formats:(NSArray<NSString *> *)formats
     options:(NSDictionary *)options {
  // This plugin initializes the barcode reader only the first time to
  // maximize performance.
  if (_reader == nil) {
    _hints = [[self class] hintsWithFormats:formats options:options];
    _delegateReader = [[self class] createMultiFormatReaderWithHints:_hints];
    _reader = [[self class] createWrappedReaderWithDelegate:_delegateReader
                                                    formats:formats
                                                    options:options];
  }

  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(frame.buffer);
  CGImageRef videoFrameImage = NULL;

  if (VTCreateCGImageFromCVPixelBuffer(pixelBuffer, NULL, &videoFrameImage) !=
      errSecSuccess) {
    return [NSNull null];
  }

  // We don't need to rotate an image manually.
  // VTCreateCGImageFromCVPixelBuffer() function already rotated it for us.

  // TODO: If scanRect is set, crop the current image to include only the
  // desired rect

  const size_t imageWidth = CGImageGetWidth(videoFrameImage);
  const size_t imageHeight = CGImageGetHeight(videoFrameImage);

  _nScanned++;

  /*
  // DEBUG: Get JPEG representation for debug.
  if (_nScanned % 30 == 0) {
    CGImageRef targetImage = rotatedImage;
    // CGImageRef targetImage = videoFrameImage;

    // UIImage *img = [UIImage imageWithCGImage:rotatedImage
    //                                    scale:1.0f
    //                              orientation:orientation];
    UIImage *img = [UIImage imageWithCGImage:targetImage];
    NSData *bitmapRep = UIImageJPEGRepresentation(img, 0.6f);
    NSString *base64JPEG = [bitmapRep base64EncodedStringWithOptions:0];

    return @{
      @"width" : @(CGImageGetWidth(targetImage)),
      @"height" : @(CGImageGetHeight(targetImage)),
      @"base64JPEG" : base64JPEG
    };
  }
  */

  ZXCGImageLuminanceSource *source =
      [[ZXCGImageLuminanceSource alloc] initWithCGImage:videoFrameImage];
  ZXHybridBinarizer *binarizer =
      [[ZXHybridBinarizer alloc] initWithSource:source];
  ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];

  NSError *error = nil;
  NSArray<ZXResult *> *results = [self.reader decodeMultiple:bitmap
                                                       hints:self.hints
                                                       error:&error];

  CGImageRelease(videoFrameImage);

  if (results != nil) {
    NSMutableArray *barcodes = [NSMutableArray arrayWithCapacity:results.count];

    for (ZXResult *result in results) {
      // The barcode format, such as a QR code or UPC-A
      const ZXBarcodeFormat format = result.barcodeFormat;

      // We have to convert keys in resultMetadata to string due to
      // VisionCamera limitation.
      NSMutableDictionary *meradata = [@{} mutableCopy];

      if (result.resultMetadata != nil) {
        for (id key in result.resultMetadata) {
          id value = result.resultMetadata[key];
          NSString *stringKey =
              [key isKindOfClass:[NSNumber class]]
                  ? createStringFromZXResultMetadataType([key intValue])
                  : [key description];

          // NSLog(@"metadata: %@ = %@", stringKey, value);
          meradata[stringKey] = convertMetadataValue(value);
        }

        // QRCode: Structured append
        NSNumber *saSeq =
            result
                .resultMetadata[@(kResultMetadataTypeStructuredAppendSequence)];
        if (saSeq != nil) {
          const uint8_t seq = [saSeq unsignedCharValue];

          // +--------------------+-------------------+-------------------+
          // | mode (4bits = 0x3) | seq index (4bits) | seq total (4bits) |
          // +--------------------+-------------------+-------------------+

          const int index = seq >> 4;
          const int total = (seq & 0x0f) + 1;

          meradata[@"structuredAppendIndex"] = @(index);
          meradata[@"structuredAppendTotal"] = @(total);
        }
      }

      // Convert points
      NSMutableArray *points = [NSMutableArray arrayWithCapacity:4];
      if (result.resultPoints) {
        for (ZXResultPoint *pt in result.resultPoints) {
          [points addObject:convertZXResultPoint(pt)];
        }
      }

      [barcodes addObject:@{
        // raw text encoded by the barcode
        @"text" : result.text,
        // representing the format of the barcode that was decoded
        @"format" : createStringFromZXBarcodeFormat(format),
        // points related to the barcode in the image. These are typically
        // points identifying finder patterns or the corners of the barcode.
        // The
        // exact meaning is specific to the type of barcode that was decoded.
        @"cornerPoints" : points,
        // mapping ZXResultMetadataType keys to values. May be nil. This
        // contains
        // optional metadata about what was detected about the barcode, like
        // orientation.
        @"metadata" : meradata,
      }];
    }

    return @{
      @"width" : @(imageWidth),
      @"height" : @(imageHeight),
      @"barcodes" : barcodes
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

  return @{
    @"width" : @(imageWidth),
    @"height" : @(imageHeight),
    @"barcodes" : @[],
  };
}
@end
