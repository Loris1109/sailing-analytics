import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  //Rotations Geschwindigkeit
  static Stream<GyroscopeEvent> getGyroscopeStream() {
    return gyroscopeEventStream().handleError((error) {
      // Sensor not available on this device (common on Android emulators)
      //throw Error incase of UI notification
    });
  }

  //Kompass
  static Stream<MagnetometerEvent> getMagnetometerStream() {
    return magnetometerEventStream().handleError((error) {
      // Sensor not available on this device (common on Android emulators)
      //throw Error incase of UI notification
    });
  }

  //für heel und pitch
  static Stream<AccelerometerEvent> getAccelerometerStream() {
    return accelerometerEventStream().handleError((error) {
      // Sensor not available on this device (common on Android emulators)
      //throw Error incase of UI notification
    });
  }
}
