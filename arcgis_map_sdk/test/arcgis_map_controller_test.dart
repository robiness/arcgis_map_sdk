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
}

class _RecordingPlatform extends ArcgisMapPlatform {
  final calls = <(String method, int mapId, Object? argument)>[];

  final styleLayerCalls = <({int mapId, List<String> ids, bool visible})>[];

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
}
