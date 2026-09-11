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
  'Europe': (maxSpeed: 9.0, tackAngle: 90.0),
};
