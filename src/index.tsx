import { NativeModules, Platform } from 'react-native';
import type { Frame } from 'react-native-vision-camera';

const LINKING_ERROR =
  `The package 'vision-camera-plugin-zxing' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const VisionCameraPluginZxing = NativeModules.VisionCameraPluginZxing
  ? NativeModules.VisionCameraPluginZxing
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export function multiply(a: number, b: number): Promise<number> {
  return VisionCameraPluginZxing.multiply(a, b);
}

/**
 * Scans barcodes in the passed frame with Zxing
 *
 * @param frame Camera frame
 * @param types Array of barcode types to detect (for optimal performance, use less types)
 * @returns Detected barcodes from Zxing
 */
export function scanBarcodes(frame: Frame, types: any[], options?: any): any[] {
  'worklet';
  // @ts-ignore
  // eslint-disable-next-line no-undef
  return __scanBarcodes(frame, types, options);
}
