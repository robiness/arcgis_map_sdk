import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/src/arcgis_map_sdk_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'mocks.dart';

void main() {
  group('ArcgisMapWeb', () {
    late ArcgisMapWeb arcgisMapWeb;
    late MockArcgisMapWebController mockController;

    setUp(() {
      mockController = MockArcgisMapWebController();
      arcgisMapWeb = ArcgisMapWeb();
      ArcgisMapWeb.controllers[1] = mockController;
    });

    test('polygonContainsPoint returns true when point is inside polygon', () {
      when(
        mockController.polygonContainsPoint(
          polygonId: 'polygon1',
          pointCoordinates: const LatLng(1, 1),
        ),
      ).thenReturn(true);

      final result = arcgisMapWeb.polygonContainsPoint(
        mapId: 1,
        polygonId: 'polygon1',
        pointCoordinates: const LatLng(1, 1),
      );

      expect(result, isTrue);
    });

    test('polygonContainsPoint returns false when point is outside polygon',
        () {
      when(
        mockController.polygonContainsPoint(
          polygonId: 'polygon1',
          pointCoordinates: const LatLng(2, 2),
        ),
      ).thenReturn(false);

      final result = arcgisMapWeb.polygonContainsPoint(
        mapId: 1,
        polygonId: 'polygon1',
        pointCoordinates: const LatLng(2, 2),
      );

      expect(result, isFalse);
    });
  });
}
