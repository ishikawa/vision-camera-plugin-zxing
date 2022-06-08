#import "VisionCameraPluginZxing.h"
#import "VCZBarCodeScanner.h"
#import <VisionCamera/Frame.h>
#import <VisionCamera/FrameProcessorPlugin.h>

static VCZBarCodeScanner *barCodeScanner = nil;

@implementation VisionCameraPluginZxing

+ (void)load {
  // Initialzie class properties.
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    barCodeScanner = [[VCZBarCodeScanner alloc] init];
  });

  // Register VisionCamera frame processor
  [FrameProcessorPluginRegistry
      addFrameProcessorPlugin:@"__scanBarCodes"
                     callback:^id(Frame *frame, NSArray<id> *args) {
                       return [barCodeScanner scan:frame args:args];
                     }];
}

@end
