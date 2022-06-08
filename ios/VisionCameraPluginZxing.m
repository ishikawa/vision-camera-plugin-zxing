#import "VisionCameraPluginZxing.h"
#import <VideoToolbox/VideoToolbox.h>
#import <VisionCamera/Frame.h>
#import <VisionCamera/FrameProcessorPlugin.h>
#import <ZXingObjC/ZXingObjC.h>

@implementation VisionCameraPluginZxing

static NSUInteger nScanned = 0;

static inline id scanBarcodes(Frame *frame, NSArray *args) {

  const UIImageOrientation orientation = frame.orientation;
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(frame.buffer);
  CGImageRef videoFrameImage = NULL;

  if (VTCreateCGImageFromCVPixelBuffer(pixelBuffer, NULL, &videoFrameImage) !=
      errSecSuccess) {
    return @[];
  }

  // DEBUG: Get JPEG representation for debug.
  if (nScanned++ % 30 == 0) {
    UIImage *img = [UIImage imageWithCGImage:videoFrameImage
                                       scale:1.0f
                                 orientation:orientation];
    NSData *bitmapRep = UIImageJPEGRepresentation(img, 0.3f);
    NSString *base64JPEG = [bitmapRep base64EncodedStringWithOptions:0];

    return @[ @{@"base64JPEG" : base64JPEG} ];
  }

  /*
  // TODO: createImageFromBuffer() allocate memory. Can I reduce it?
  CGImageRef videoFrameImage =
      [ZXCGImageLuminanceSource createImageFromBuffer:videoFrame];
  */

  // TODO: If scanRect is set, crop the current image to include only the
  // desired rect

  // TODO: Rotate image if needed?

  ZXCGImageLuminanceSource *source =
      [[ZXCGImageLuminanceSource alloc] initWithCGImage:videoFrameImage];
  ZXHybridBinarizer *binarizer =
      [[ZXHybridBinarizer alloc] initWithSource:[source invert]];
  ZXBinaryBitmap *bitmap = [[ZXBinaryBitmap alloc] initWithBinarizer:binarizer];

  // TODO: Pass hints via arguments?
  // There are a number of hints we can give to the reader, including
  // possible formats, allowed lengths, and the string encoding.
  ZXDecodeHints *hints = [ZXDecodeHints hints];

  // TODO: it can be shared
  ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];

  NSError *error = nil;
  ZXResult *result = [reader decode:bitmap hints:hints error:&error];

  CGImageRelease(videoFrameImage);

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

VISION_EXPORT_FRAME_PROCESSOR(scanBarcodes)

@end
