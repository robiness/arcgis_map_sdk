@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:ui';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
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

  test('a pending load that fails settles only once the layer has left the map',
      () async {
    final constructed = installFakeVectorTileLayers();
    final map = _mapWithLabelsAndMarkers();

    List<String>? layerIdsWhenSettled;
    bool? destroyedWhenSettled;
    final adding = WebLayerController(mapId: 1)
        .addVectorTileLayer(
      layerId: 'counties',
      style: _style,
      view: FakeView(map).js,
    )
        .then<void>(
      (_) {},
      onError: (Object _) {
        layerIdsWhenSettled = map.layerIds;
        destroyedWhenSettled = constructed.single.destroyed;
      },
    );
    await pumpEventQueue();
    expect(map.layerIds, ['labels', 'markers', 'counties']);

    constructed.single.failLoad('request:server', 'Unauthorized');
    await adding;

    expect(layerIdsWhenSettled, ['labels', 'markers']);
    expect(destroyedWhenSettled, isTrue);
  });

  test('a layer that fails to load is forgotten, so its id finds no layer',
      () async {
    final constructed = installFakeVectorTileLayers();
    final view = FakeView(_mapWithLabelsAndMarkers()).js;
    final controller = WebLayerController(mapId: 1);

    final failing = controller.addVectorTileLayer(
      layerId: 'counties',
      style: _style,
      view: view,
    );
    constructed.single.failLoad('request:server', 'Unauthorized');
    await expectLater(failing, throwsException);

    await expectLater(
      controller.addGraphic(
        layerId: 'counties',
        graphic: PointGraphic(
          latitude: 53.4105,
          longitude: -6.44,
          attributes: Attributes({'id': 'clonee'}),
          symbol: const SimpleMarkerSymbol(
            color: Color(0xFFFF0000),
            outlineColor: Color(0xFFFFFFFF),
          ),
        ),
        view: view,
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'toString()',
          contains('Layer with id counties not found'),
        ),
      ),
    );
  });

  test(
      'a load rejected with something other than an ArcGIS error names the layer',
      () async {
    final constructed = installFakeVectorTileLayers();
    final view = FakeView(_mapWithLabelsAndMarkers()).js;
    final controller = WebLayerController(mapId: 1);
    Matcher namesTheLayer(String text) => throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            allOf(contains('counties'), contains(text)),
          ),
        );

    final rejectedWithNull = controller.addVectorTileLayer(
      layerId: 'counties',
      style: _style,
      view: view,
    );
    constructed.last.rejectLoad(null);
    await expectLater(rejectedWithNull, namesTheLayer('null'));

    final rejectedWithText = controller.addVectorTileLayer(
      layerId: 'counties',
      style: _style,
      view: view,
    );
    constructed.last.rejectLoad('Request canceled'.toJS);
    await expectLater(rejectedWithText, namesTheLayer('Request canceled'));
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
