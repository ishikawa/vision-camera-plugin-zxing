#import "VisionCameraPluginZxing.h"
#import <VisionCamera/Frame.h>
#import <VisionCamera/FrameProcessorPlugin.h>

@implementation VisionCameraPluginZxing

static inline id scanBarcodes(Frame *frame, NSArray *args) {
  CMSampleBufferRef buffer = frame.buffer;
  UIImageOrientation orientation = frame.orientation;
  // code goes here
  return @[ @12345 ];
}

VISION_EXPORT_FRAME_PROCESSOR(scanBarcodes)

@end
