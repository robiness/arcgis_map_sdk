import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two moves with the same values are equal', () {
    const a = MapPointerMove(
      x: 1,
      y: 2,
      timeStamp: 3,
      buttons: 1,
      mapPoint: LatLng(53, -6),
      overMap: true,
    );
    const b = MapPointerMove(
      x: 1,
      y: 2,
      timeStamp: 3,
      buttons: 1,
      mapPoint: LatLng(53, -6),
      overMap: true,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(
        const MapPointerMove(
          x: 1,
          y: 2,
          timeStamp: 3,
          buttons: 1,
          mapPoint: null,
          overMap: false,
        ),
      ),
    );
  });

  test('the platform without an implementation says so', () {
    expect(
        () => _BarePlatform().pointerMoveStream(1), throwsUnimplementedError);
  });
}

class _BarePlatform extends ArcgisMapPlatform {}
