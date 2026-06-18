import 'package:sensors_plus/sensors_plus.dart' hide SensorInterval;
import 'package:flutter_rotation_sensor/flutter_rotation_sensor.dart';

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

  static Stream<OrientationEvent> getOrientationStream() {
    RotationSensor.samplingPeriod = SensorInterval.fastestInterval;
    RotationSensor.coordinateSystem = CoordinateSystem.transformed(
      Axis3.X,
      -Axis3.Z,
    );
    return RotationSensor.orientationStream.handleError((_) {});
  }
}
