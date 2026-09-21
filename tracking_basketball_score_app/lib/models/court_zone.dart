enum CourtZone {
  leftCorner('Left corner'),
  leftWing('Left wing'),
  top('Top'),
  rightWing('Right wing'),
  rightCorner('Right corner'),
  midRange('Mid-range'),
  paint('Paint');

  const CourtZone(this.label);

  final String label;

  static CourtZone? fromName(String? name) {
    for (final zone in values) {
      if (zone.name == name) {
        return zone;
      }
    }
    return null;
  }
}
