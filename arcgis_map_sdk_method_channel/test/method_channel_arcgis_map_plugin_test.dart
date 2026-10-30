import 'package:arcgis_map_sdk_method_channel/arcgis_map_sdk_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('web only', () {
    test('request headers are web only', () {
      final plugin = MethodChannelArcgisMapPlugin();
      const prefix = 'https://api.test/graphql/boundaries/';

      expect(
        () => plugin.setRequestHeaders(
          mapId: 1,
          urlPrefix: prefix,
          headers: () async => {},
        ),
        throwsUnimplementedError,
      );
      expect(
        () => plugin.clearRequestHeaders(mapId: 1, urlPrefix: prefix),
        throwsUnimplementedError,
      );
    });

    test('basemap style layers are web only', () {
      expect(
        () => MethodChannelArcgisMapPlugin().setBasemapStyleLayersVisible(
          mapId: 1,
          styleLayerIds: ['administrative boundary/level 6/line'],
          visible: false,
        ),
        throwsUnimplementedError,
      );
    });
  });
}
