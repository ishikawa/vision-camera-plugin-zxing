import 'react-native-reanimated';
import React, { useEffect, useState } from 'react';
import {
  Alert,
  SafeAreaView,
  StatusBar,
  StyleSheet,
  LayoutRectangle,
  StyleProp,
  ViewStyle,
} from 'react-native';
import {
  Camera,
  useCameraDevices,
  useFrameProcessor,
} from 'react-native-vision-camera';
import Animated, {
  useAnimatedStyle,
  withTiming,
  useSharedValue,
} from 'react-native-reanimated';
import { detectBarcodes, DetectionResult } from 'vision-camera-plugin-zxing';

const App: React.FC = () => {
  const cameraDevices = useCameraDevices();
  const cameraDevice = cameraDevices.back;
  const [hasCameraPermission, setHasCameraPermission] = useState(false);

  // Animation values
  const cameraRect = useSharedValue<LayoutRectangle | null>(null);
  const scanResult = useSharedValue<DetectionResult | null>(null);

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

  // uses 'scanResult' to position the rectangle on screen.
  // smoothly updates on UI thread whenever 'scanResult' is changed
  const boxOverlayStyle: StyleProp<ViewStyle> = useAnimatedStyle(() => {
    if (cameraRect.value && scanResult.value?.code?.points.length === 4) {
      const points = scanResult.value.code.points;

      const scaleX = cameraRect.value.width / scanResult.value.width;
      const scaleY = cameraRect.value.height / scanResult.value.height;

      const minX = Math.min(...points.map((pt) => pt.x)) * scaleX;
      const minY = Math.min(...points.map((pt) => pt.y)) * scaleY;
      const maxX = Math.max(...points.map((pt) => pt.x)) * scaleX;
      const maxY = Math.max(...points.map((pt) => pt.y)) * scaleY;
      const bounds = {
        x: minX,
        y: minY,
        width: maxX - minX,
        height: maxY - minY,
      };
      const animationOptions = {
        duration: 100,
      };

      return {
        position: 'absolute',
        borderWidth: 2,
        borderColor: 'red',
        left: withTiming(bounds.x, animationOptions),
        top: withTiming(bounds.y, animationOptions),
        width: bounds.width,
        height: bounds.height,
      };
    } else {
      return {
        visibility: 'hidden',
      };
    }
  });

  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    const value = detectBarcodes(frame, []);

    if (value) {
      if (value.base64JPEG) {
        console.log(value);
      }
      if (value.code) {
        scanResult.value = value;
      }
    }
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      {cameraDevice && hasCameraPermission ? (
        <Camera
          frameProcessor={frameProcessor}
          style={[styles.camera]}
          device={cameraDevice}
          isActive={true}
          onLayout={({ nativeEvent: { layout } }) => {
            cameraRect.value = layout;
          }}
        >
          <Animated.View style={boxOverlayStyle} />
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
