#import "VisionCameraPluginZxing.h"
#import "VCZBarcodeScanner.h"
#import <VisionCamera/Frame.h>
#import <VisionCamera/FrameProcessorPlugin.h>

static VCZBarcodeScanner *barCodeScanner = nil;

@implementation VisionCameraPluginZxing

+ (void)load {
  // Initialzie class properties.
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    barCodeScanner = [[VCZBarcodeScanner alloc] init];
  });

  // Register VisionCamera frame processor
  [FrameProcessorPluginRegistry
      addFrameProcessorPlugin:@"__detectBarcodes"
                     callback:^id(Frame *frame, NSArray<id> *args) {
                       return [barCodeScanner scan:frame args:args];
                     }];
}

@end
