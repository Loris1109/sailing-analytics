// lib/data/entities/boat_class.dart
// Voreinstellungen pro Bootsklasse. Beim Anlegen eines Boots werden sie
// auf das Boot kopiert und dort eingefroren — ändert sich hier später ein
// Wert, bleiben bestehende Boote bei dem, womit ihre Sessions gerechnet
// wurden.
//
// Lag vorher im AddBoatDialog. Steht hier, weil es Fachdaten sind: die
// Migration und die Wendenerkennung greifen ebenfalls darauf zu.

typedef BoatClassProfile = ({
  /// Knoten. Obergrenze der Farbskala für den Track auf der Karte.
  double maxSpeed,

  /// Grad zwischen den beiden Am-Wind-Kursen.
  double tackAngle,
});

const Map<String, BoatClassProfile> kBoatClasses = {
  'Europe': (maxSpeed: 12.0, tackAngle: 90.0),
  'Laser': (maxSpeed: 15, tackAngle: 90),
  'OK': (maxSpeed: 15, tackAngle: 90),
  'Pirat': (maxSpeed: 12, tackAngle: 90),
  '420er': (maxSpeed: 15, tackAngle: 90),
  '29er': (maxSpeed: 20, tackAngle: 100),
  '49er': (maxSpeed: 25, tackAngle: 90),

};
