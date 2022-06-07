import type { Frame } from 'react-native-vision-camera';

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
