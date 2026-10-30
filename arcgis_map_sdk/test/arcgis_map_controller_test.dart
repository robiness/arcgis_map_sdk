import 'package:arcgis_map_sdk/arcgis_map_sdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _RecordingPlatform platform;
  late ArcgisMapController controller;

  setUp(() async {
    ArcgisMapPlatform.instance = platform = _RecordingPlatform();
    controller = await ArcgisMapController.init(7);
  });

  test('request headers reach the platform with the map id', () {
    const prefix = 'https://api.test/graphql/boundaries/';
    Future<Map<String, String>> headers() async =>
        {'Authorization': 'Bearer t'};

    controller.setRequestHeaders(urlPrefix: prefix, headers: headers);
    controller.clearRequestHeaders(urlPrefix: prefix);

    expect(platform.calls, [
      ('setRequestHeaders', 7, prefix),
      ('clearRequestHeaders', 7, prefix),
    ]);
    expect(identical(platform.requestHeaders, headers), isTrue);
  });

  test('basemap style layers reach the platform with the map id', () async {
    const ids = ['administrative boundary/level 6/line'];

    await controller.setBasemapStyleLayersVisible(
      styleLayerIds: ids,
      visible: false,
    );

    expect(platform.styleLayerCalls, [(mapId: 7, ids: ids, visible: false)]);
  });

  test('a vector tile layer reaches the platform with the map id', () async {
    final style = <String, Object?>{'version': 8, 'layers': <Object?>[]};

    await controller.addVectorTileLayer(
      layerId: 'counties',
      style: style,
      index: 0,
    );

    expect(
      platform.vectorTileLayerCalls,
      [(mapId: 7, layerId: 'counties', index: 0)],
    );
    expect(identical(platform.vectorTileStyle, style), isTrue);
  });

  test('style and visibility reach the platform with the map id', () async {
    final style = <String, Object?>{'version': 8, 'layers': <Object?>[]};

    await controller.setVectorTileStyle(layerId: 'counties', style: style);
    controller.setLayerVisibility(layerId: 'counties', visible: false);

    expect(platform.calls, [
      ('setVectorTileStyle', 7, 'counties'),
      ('setLayerVisibility', 7, ('counties', false)),
    ]);
    expect(identical(platform.vectorTileStyle, style), isTrue);
  });
}

class _RecordingPlatform extends ArcgisMapPlatform {
  final calls = <(String method, int mapId, Object? argument)>[];

  final styleLayerCalls = <({int mapId, List<String> ids, bool visible})>[];

  final vectorTileLayerCalls = <({int mapId, String layerId, int? index})>[];

  Map<String, Object?>? vectorTileStyle;

  Future<Map<String, String>> Function()? requestHeaders;

  @override
  Future<void> init(int mapId) async {}

  @override
  Future<void> setMethodCallHandler({
    required int mapId,
    required Future<dynamic> Function(MethodCall) onCall,
  }) async {}

  @override
  void setRequestHeaders({
    required int mapId,
    required String urlPrefix,
    required Future<Map<String, String>> Function() headers,
  }) {
    calls.add(('setRequestHeaders', mapId, urlPrefix));
    requestHeaders = headers;
  }

  @override
  void clearRequestHeaders({required int mapId, required String urlPrefix}) {
    calls.add(('clearRequestHeaders', mapId, urlPrefix));
  }

  @override
  Future<void> setBasemapStyleLayersVisible({
    required int mapId,
    required List<String> styleLayerIds,
    required bool visible,
  }) async {
    styleLayerCalls.add((mapId: mapId, ids: styleLayerIds, visible: visible));
  }

  @override
  Future<void> addVectorTileLayer({
    required int mapId,
    required String layerId,
    required Map<String, Object?> style,
    int? index,
  }) async {
    vectorTileLayerCalls.add((mapId: mapId, layerId: layerId, index: index));
    vectorTileStyle = style;
  }

  @override
  Future<void> setVectorTileStyle({
    required int mapId,
    required String layerId,
    required Map<String, Object?> style,
  }) async {
    calls.add(('setVectorTileStyle', mapId, layerId));
    vectorTileStyle = style;
  }

  @override
  void setLayerVisibility({
    required int mapId,
    required String layerId,
    required bool visible,
  }) {
    calls.add(('setLayerVisibility', mapId, (layerId, visible)));
  }
}
