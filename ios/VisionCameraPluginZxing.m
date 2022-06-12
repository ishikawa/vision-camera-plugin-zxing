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
                       id formats = args.count >= 1 ? args[0] : @[];
                       id options = args.count >= 2 ? args[1] : @{};

                       return [barCodeScanner detect:frame
                                             formats:formats
                                             options:options];
                     }];
}

@end
