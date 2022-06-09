import 'react-native-reanimated';
import React, { useEffect, useState } from 'react';
import { Alert, SafeAreaView, StatusBar, StyleSheet } from 'react-native';
import {
  Camera,
  useCameraDevices,
  useFrameProcessor,
} from 'react-native-vision-camera';
import { scanBarCodes } from 'vision-camera-plugin-zxing';

const App: React.FC = () => {
  const cameraDevices = useCameraDevices();
  const cameraDevice = cameraDevices.back;
  const [hasCameraPermission, setHasCameraPermission] = useState(false);

  const frameProcessor = useFrameProcessor((frame) => {
    'worklet';
    const value = scanBarCodes(frame, []);

    if (value.length > 0) {
      console.log('value =', value[0]);
    }
  }, []);

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
        />
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
