import type { Frame } from 'react-native-vision-camera';

export type BarcodePoint = {
  x: number;
  y: number;
};

export type BarcodeMetadata = {
  /**
   * Unspecified, application-specific metadata. Maps to an unspecified
   * NSObject.
   */
  other?: unknown;

  /**
   * Denotes the likely approximate orientation of the barcode in the image.
   * This value is given as degrees rotated clockwise from the normal, upright
   * orientation. For example a 1D barcode which was found by reading
   * top-to-bottom would be said to have orientation "90". This key maps to an
   * integer whose value is in the range [0,360).
   */
  orientation?: unknown;

  /**
   * 2D barcode formats typically encode text, but allow for a sort of 'byte
   * mode' which is sometimes used to encode binary data. While ZXResult makes
   * available the complete raw bytes in the barcode for these formats, it does
   * not offer the bytes from the byte segments alone.
   *
   * This maps to an array of byte arrays corresponding to the
   * raw bytes in the byte segments in the barcode, in order.
   *
   * byteSegments is an array of base64 encoded string.
   */
  byteSegments?: string[];

  /**
   * Error correction level used, if applicable. The value type depends on the
   * format, but is typically a String.
   */
  errorCorrectionLevel?: unknown;

  /**
   * For some periodicals, indicates the issue number as an integer.
   */
  issueNumber?: number;

  /**
   * For some products, indicates the suggested retail price in the barcode as a
   * formatted NSString.
   */
  suggestedPrice?: string;

  /**
   * For some products, the possible country of manufacture as NSString denoting
   * the ISO country code. Some map to multiple possible countries, like
   * "US/CA".
   */
  possibleCountry?: string;

  /**
   * For some products, the extension text
   */
  UPCEANExtension?: string;

  /**
   * PDF417-specific metadata
   */
  PDF417ExtraMetadata?: unknown;

  /**
   * If the code format supports structured append and the current scanned code
   * is part of one then the sequence number is given with it.
   */
  structuredAppendSequence?: number;

  /**
   * If the code format supports structured append and the current scanned
   * code is part of one then the parity is given with it.
   */
  structuredAppendParity?: number;

  /**
   * If the code format supports structured append and the current scanned
   * code is part of one then the index is given with it.
   */
  structuredAppendIndex?: number;

  /**
   * If the code format supports structured append and the current scanned
   * code is part of one then the total number is given with it.
   */
  structuredAppendTotal?: number;
};

export type BarcodeFormat =
  /** Aztec 2D barcode format. */
  | 'Aztec'

  /** CODABAR 1D format. */
  | 'Codabar'

  /** Code 39 1D format. */
  | 'Code39'

  /** Code 93 1D format. */
  | 'Code93'

  /** Code 128 1D format. */
  | 'Code128'

  /** Data Matrix 2D barcode format. */
  | 'DataMatrix'

  /** EAN-8 1D format. */
  | 'Ean8'

  /** EAN-13 1D format. */
  | 'Ean13'

  /** ITF (Interleaved Two of Five) 1D format. */
  | 'ITF'

  /** MaxiCode 2D barcode format. */
  | 'MaxiCode'

  /** PDF417 format. */
  | 'PDF417'

  /** QR Code 2D barcode format. */
  | 'QRCode'

  /** RSS 14 */
  | 'RSS14'

  /** RSS EXPANDED */
  | 'RSSExpanded'

  /** UPC-A 1D format. */
  | 'UPCA'

  /** UPC-E 1D format. */
  | 'UPCE'

  /** UPC/EAN extension format. Not a stand-alone format. */
  | 'UPCEANExtension';

export type Barcode = {
  text: string;
  format: BarcodeFormat;
  // points related to the barcode in the image. These are typically
  // points identifying finder patterns or the corners of the barcode. The
  // exact meaning is specific to the type of barcode that was decoded.
  cornerPoints: BarcodePoint[];
  metadata: BarcodeMetadata;
};

export type DetectionResult = {
  barcodes: Barcode[];
  width: number;
  height: number;
  // DEBUG purpose only.
  base64JPEG?: string;
};

export type DetectionOptions = {
  /**
   * Spend more time to try to find a barcode; optimize for accuracy, not speed.
   *
   * Default: `false`
   */
  accurate?: boolean;

  /**
   * Whether the scanner attempts to decode a barcode from an image, not by scanning the whole image,
   * but by scanning subsets of the image. This is important when there may be multiple barcodes in
   * an image, and detecting a barcode may find parts of multiple barcode and fail to decode
   * (e.g. QR Codes). Instead this scans the four quadrants of the image -- and also the center
   * 'quadrant' to cover the case where a barcode is found in the center.
   *
   * Default: `false`
   */
  readByQuadrant?: boolean;

  /**
   * Whether the scanner attempt to read several barcodes from one image.
   *
   * Default: `false`
   */
  readMultiple?: boolean;
};

/**
 * Scans barcodes in the passed frame with Zxing
 *
 * @param frame Camera frame
 * @param formats Array of barcode formats to detect (for optimal performance, use less types)
 * @returns Detected barcodes from Zxing. Returns `null` if there was unexpected error or
 *          frame processor took too long to execute.
 */
export function detectBarcodes(
  frame: Frame,
  formats: BarcodeFormat[],
  options: DetectionOptions = {}
): DetectionResult | null {
  'worklet';
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  return __detectBarcodes(frame, formats, options);
}
