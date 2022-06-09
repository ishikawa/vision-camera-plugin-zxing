import 'react-native-reanimated';
import React, { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  View,
  SafeAreaView,
  StatusBar,
  StyleSheet,
  LayoutRectangle,
} from 'react-native';
import {
  Camera,
  useCameraDevices,
  useFrameProcessor,
} from 'react-native-vision-camera';
import { runOnJS } from 'react-native-reanimated';
import { scanBarCodes, ScanResult } from 'vision-camera-plugin-zxing';

const App: React.FC = () => {
  const cameraDevices = useCameraDevices();
  const cameraDevice = cameraDevices.back;
  const [hasCameraPermission, setHasCameraPermission] = useState(false);
  const [, setScanResult] = useState<ScanResult | null>(null);
  const [codeRect, setCodeRect] = useState<LayoutRectangle | null>(null);
  const [cameraRect, setCameraRect] = useState<LayoutRectangle | null>(null);

  // Camera permission
  useEffect(() => {
    (async () => {
      const cameraPermission = await Camera.getCameraPermissionStatus();

      switch (cameraPermission) {
        case 'authorized':
          setHasCameraPermission(true);
          return;
        case 'denied':
        case 'restricted':
          Alert.alert(
            'Permission required',
            'The app does not have the permission to access camera. Please grant it.'
          );
          return;
      }

      const newCameraPermission = await Camera.requestCameraPermission();

      switch (newCameraPermission) {
        case 'authorized':
          return;
        case 'denied':
          Alert.alert(
            'Permission required',
            'The app does not have the permission to access camera. Please grant it.'
          );
          return;
      }
    })();
  }, []);

  const onScanBarCode = useCallback(
    (scanResult: ScanResult) => {
      console.log('scanResult =', scanResult, 'cameraRect =', cameraRect);
      setScanResult(scanResult);

      if (cameraRect && scanResult.code?.points.length === 4) {
        const points = scanResult.code.points;

        const scaleX = cameraRect.width / scanResult.width;
        const scaleY = cameraRect.height / scanResult.height;

        const minX = Math.min(...points.map((pt) => pt.x)) * scaleX;
        const minY = Math.min(...points.map((pt) => pt.y)) * scaleY;
        const maxX = Math.max(...points.map((pt) => pt.x)) * scaleX;
        const maxY = Math.max(...points.map((pt) => pt.y)) * scaleY;

        setCodeRect({
          x: minX,
          y: minY,
          width: maxX - minX,
          height: maxY - minY,
        });
      } else {
        setCodeRect(null);
      }
    },
    [cameraRect]
  );

  const frameProcessor = useFrameProcessor(
    (frame) => {
      'worklet';
      const value = scanBarCodes(frame, []);

      if (value) {
        if (value.base64JPEG) {
          console.log(value);
        }
        if (value.code) {
          runOnJS(onScanBarCode)(value);
        }
      }
    },
    [onScanBarCode]
  );

  return (
    <SafeAreaView style={styles.container}>
      {cameraDevice && hasCameraPermission ? (
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        <Camera
          frameProcessor={frameProcessor}
          style={[styles.camera]}
          device={cameraDevice}
          isActive={true}
          onLayout={({ nativeEvent: { layout } }) => {
            setCameraRect(layout);
          }}
        >
          {codeRect && (
            <View
              style={{
                position: 'absolute',
                borderWidth: 2,
                borderColor: 'red',
                left: codeRect.x,
                top: codeRect.y,
                width: codeRect.width,
                height: codeRect.height,
              }}
            />
          )}
        </Camera>
      ) : null}
      <StatusBar barStyle="default" />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  camera: {
    flex: 1,
  },
});

export default App;
