import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';

/// A move of the pointer over the map view.
class MapPointerMove {
  const MapPointerMove({
    required this.x,
    required this.y,
    required this.timeStamp,
    required this.buttons,
    required this.mapPoint,
    required this.overMap,
  });

  /// Horizontal position in logical pixels from the view's left edge.
  final double x;

  /// Vertical position in logical pixels from the view's top edge.
  final double y;

  /// Milliseconds on the page's event clock (the native event's `timeStamp`).
  final double timeStamp;

  /// The PointerEvent bitmask of the pressed buttons, 0 when none is pressed.
  final int buttons;

  /// The map point under the pointer. Null where the view gives none (the sky
  /// of a 3D view) and on a leave.
  final LatLng? mapPoint;

  /// False only when the pointer has left the map, onto the app's own
  /// controls.
  final bool overMap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPointerMove &&
          other.x == x &&
          other.y == y &&
          other.timeStamp == timeStamp &&
          other.buttons == buttons &&
          other.mapPoint == mapPoint &&
          other.overMap == overMap;

  @override
  int get hashCode => Object.hash(x, y, timeStamp, buttons, mapPoint, overMap);

  @override
  String toString() => 'MapPointerMove(x: $x, y: $y, timeStamp: $timeStamp, '
      'buttons: $buttons, mapPoint: $mapPoint, overMap: $overMap)';
}
