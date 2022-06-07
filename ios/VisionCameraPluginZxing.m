#import "VisionCameraPluginZxing.h"
#import <VisionCamera/Frame.h>
#import <VisionCamera/FrameProcessorPlugin.h>

@implementation VisionCameraPluginZxing

RCT_EXPORT_MODULE()

static inline id scanBarcodes(Frame *frame, NSArray *args) {
  CMSampleBufferRef buffer = frame.buffer;
  UIImageOrientation orientation = frame.orientation;
  // code goes here
  return @[];
}

VISION_EXPORT_FRAME_PROCESSOR(scanBarcodes)

// Example method
// See // https://reactnative.dev/docs/native-modules-ios
RCT_REMAP_METHOD(multiply, multiplyWithA
                 : (nonnull NSNumber *)a withB
                 : (nonnull NSNumber *)b withResolver
                 : (RCTPromiseResolveBlock)resolve withRejecter
                 : (RCTPromiseRejectBlock)reject) {
  NSNumber *result = @([a floatValue] * [b floatValue]);

  resolve(result);
}

@end
