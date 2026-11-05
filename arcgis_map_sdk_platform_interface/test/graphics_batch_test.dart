import 'dart:ui';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'without its own batch calls a platform adds one graphic at a time, '
      'in order', () async {
    final platform = _OneAtATimePlatform();
    final graphics = [_graphic('a'), _graphic('b')];

    await platform.addGraphics(7, 'pins', graphics);

    expect(platform.calls, [
      ('addGraphic', 7, 'pins', 'a'),
      ('addGraphic', 7, 'pins', 'b'),
    ]);
  });

  test('without its own batch calls a platform removes one graphic at a time',
      () async {
    final platform = _OneAtATimePlatform();

    await platform.removeGraphicsById(7, 'pins', ['a', 'b']);

    expect(platform.calls, [
      ('removeGraphic', 7, 'pins', 'a'),
      ('removeGraphic', 7, 'pins', 'b'),
    ]);
  });
}

PointGraphic _graphic(String id) => PointGraphic(
      latitude: 53.35,
      longitude: -6.26,
      attributes: Attributes({'id': id}),
      symbol: const SimpleMarkerSymbol(
        color: Color(0xFFE60000),
        outlineColor: Color(0xFFFFFFFF),
      ),
    );

class _OneAtATimePlatform extends ArcgisMapPlatform {
  final calls = <(String, int, String, String)>[];

  @override
  Future<void> addGraphic(int mapId, String layerId, Graphic graphic) async {
    calls.add(('addGraphic', mapId, layerId, graphic.getAttributesId()));
  }

  @override
  Future<void> removeGraphic(
    int mapId,
    String layerId,
    String graphicId,
  ) async {
    calls.add(('removeGraphic', mapId, layerId, graphicId));
  }
}
