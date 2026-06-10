import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  static Stream<GyroscopeEvent> getGyroscopeStream() {
    return gyroscopeEventStream().handleError((error) {
      // Sensor not available on this device (common on Android emulators)
      //throw Error incase of UI notification
    });
  }

  static Stream<MagnetometerEvent> getMagnetometerStream() {
    return magnetometerEventStream().handleError((error) {
      // Sensor not available on this device (common on Android emulators)
      //throw Error incase of UI notification
    });
  }

  static Stream<UserAccelerometerEvent> getAccelerometerStream() {
    return userAccelerometerEventStream().handleError((error) {
      // Sensor not available on this device (common on Android emulators)
      //throw Error incase of UI notification
    });
  }
}
