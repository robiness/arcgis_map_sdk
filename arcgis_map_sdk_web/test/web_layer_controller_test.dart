@TestOn('browser')
library;

import 'package:arcgis_map_sdk_web/src/web_layer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_arcgis.dart';

const _style = {
  'version': 8,
  'sources': {
    'counties': {
      'type': 'vector',
      'url': 'https://api.test/graphql/boundaries/county/VectorTileServer',
    },
  },
  'layers': <Object?>[],
};

FakeMap _mapWithLabelsAndMarkers() =>
    FakeMap(layers: [FakeLayer(id: 'labels'), FakeLayer(id: 'markers')]);

void main() {
  test(
      'adds the layer with its style at the index and completes once it has loaded',
      () async {
    final constructed = installFakeVectorTileLayers();
    final map = _mapWithLabelsAndMarkers();

    var done = false;
    final adding = WebLayerController(mapId: 1)
        .addVectorTileLayer(
          layerId: 'counties',
          style: _style,
          index: 0,
          view: FakeView(map).js,
        )
        .whenComplete(() => done = true);
    await pumpEventQueue();
    expect(map.layerIds, ['counties', 'labels', 'markers']);
    expect(done, isFalse);

    constructed.single.completeLoad();
    await adding;
    expect(constructed.single.properties, {'id': 'counties', 'style': _style});
  });

  test('without an index the layer goes on top', () async {
    final constructed = installFakeVectorTileLayers();
    final map = _mapWithLabelsAndMarkers();

    final adding = WebLayerController(mapId: 1).addVectorTileLayer(
      layerId: 'counties',
      style: _style,
      view: FakeView(map).js,
    );
    constructed.single.completeLoad();
    await adding;

    expect(map.layerIds, ['labels', 'markers', 'counties']);
  });

  test(
      'a layer that fails to load leaves the map, and its id can be added again',
      () async {
    final constructed = installFakeVectorTileLayers();
    final map = _mapWithLabelsAndMarkers();
    final view = FakeView(map).js;
    final controller = WebLayerController(mapId: 1);

    final failing = controller.addVectorTileLayer(
      layerId: 'counties',
      style: _style,
      index: 0,
      view: view,
    );
    constructed.single.failLoad('request:server', 'Unauthorized');

    await expectLater(
      failing,
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'toString()',
          allOf(
            contains('counties'),
            contains('request:server'),
            contains('Unauthorized'),
          ),
        ),
      ),
    );
    expect(map.layerIds, ['labels', 'markers']);
    expect(constructed.single.destroyed, isTrue);

    final retry = controller.addVectorTileLayer(
      layerId: 'counties',
      style: _style,
      index: 0,
      view: view,
    );
    constructed.last.completeLoad();
    await retry;

    expect(constructed, hasLength(2));
    expect(map.layerIds, ['counties', 'labels', 'markers']);
  });

  test('an id already in the map is refused', () async {
    final constructed = installFakeVectorTileLayers();
    final map = _mapWithLabelsAndMarkers();
    final view = FakeView(map).js;
    final controller = WebLayerController(mapId: 1);

    final first = controller.addVectorTileLayer(
      layerId: 'counties',
      style: _style,
      view: view,
    );
    await expectLater(
      controller.addVectorTileLayer(
        layerId: 'counties',
        style: _style,
        view: view,
      ),
      throwsStateError,
    );
    constructed.single.completeLoad();
    await first;

    expect(constructed, hasLength(1));
    expect(map.layerIds, ['labels', 'markers', 'counties']);
  });
}
