@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
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

Map<String, Object?> _countyStyle({required String lineColor}) => {
      ..._style,
      'layers': [
        {
          'id': 'border',
          'type': 'line',
          'source': 'counties',
          'source-layer': 'borders',
          'paint': {'line-color': lineColor},
        },
      ],
    };

final _mapStyle = _countyStyle(lineColor: '#333333');
final _satelliteStyle = _countyStyle(lineColor: '#ffffff');

FakeMap _mapWithLabelsAndMarkers() =>
    FakeMap(layers: [FakeLayer(id: 'labels'), FakeLayer(id: 'markers')]);

/// Adds the vector tile layer `counties`, drawn from [_mapStyle], and lets it
/// load.
Future<FakeVectorTileLayer> _addLoadedCounties(
  WebLayerController layers,
  JsView view,
) async {
  final constructed = installFakeVectorTileLayers();
  final adding = layers.addVectorTileLayer(
    layerId: 'counties',
    style: _mapStyle,
    view: view,
  );
  constructed.single.completeLoad();
  await adding;
  return constructed.single;
}

Matcher _throwsNotFound(String layerId) => throwsA(
      isA<Exception>().having(
        (e) => e.toString(),
        'toString()',
        contains('Layer with id $layerId not found'),
      ),
    );

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

    final rejectedWithSymbol = controller.addVectorTileLayer(
      layerId: 'counties',
      style: _style,
      view: view,
    );
    constructed.last.rejectLoad(
      globalContext.callMethod<JSAny>('Symbol'.toJS, 'canceled'.toJS),
    );
    await expectLater(rejectedWithSymbol, namesTheLayer('canceled'));
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

  group('setVectorTileStyle', () {
    test('replaces the style of a loaded layer', () async {
      final view = FakeView(FakeMap()).js;
      final layers = WebLayerController(mapId: 1);
      final counties = await _addLoadedCounties(layers, view);

      await layers.setVectorTileStyle(
        layerId: 'counties',
        style: _satelliteStyle,
        view: view,
      );

      expect(counties.loadStyleCalls, [_satelliteStyle]);
    });

    test(
        'a style set while the layer still loads is applied once it has loaded',
        () async {
      final constructed = installFakeVectorTileLayers();
      final view = FakeView(FakeMap()).js;
      final layers = WebLayerController(mapId: 1);
      final adding = layers.addVectorTileLayer(
        layerId: 'counties',
        style: _mapStyle,
        view: view,
      );
      await pumpEventQueue();

      final swapping = layers.setVectorTileStyle(
        layerId: 'counties',
        style: _satelliteStyle,
        view: view,
      );
      await pumpEventQueue();
      expect(constructed.single.loadStyleCalls, isEmpty);

      constructed.single.completeLoad();
      await adding;
      await swapping;
      expect(constructed.single.loadStyleCalls, [_satelliteStyle]);
    });

    test(
        'a style set while the layer still loads is applied as it was when set',
        () async {
      final constructed = installFakeVectorTileLayers();
      final view = FakeView(FakeMap()).js;
      final layers = WebLayerController(mapId: 1);
      final adding = layers.addVectorTileLayer(
        layerId: 'counties',
        style: _mapStyle,
        view: view,
      );
      final style = _countyStyle(lineColor: '#ffffff');

      final swapping = layers.setVectorTileStyle(
        layerId: 'counties',
        style: style,
        view: view,
      );
      style['layers'] = <Object?>[];
      constructed.single.completeLoad();
      await adding;
      await swapping;

      expect(constructed.single.loadStyleCalls, [_satelliteStyle]);
    });

    test(
        'a style that cannot be converted throws at once, while the layer still loads',
        () async {
      final constructed = installFakeVectorTileLayers();
      final view = FakeView(FakeMap()).js;
      final layers = WebLayerController(mapId: 1);
      final adding = layers.addVectorTileLayer(
        layerId: 'counties',
        style: _mapStyle,
        view: view,
      );

      final swapping = layers.setVectorTileStyle(
        layerId: 'counties',
        style: {
          'layers': [0].map<Object?>((_) => throw StateError('no style')),
        },
        view: view,
      );
      var settled = false;
      final failing = expectLater(
        swapping.whenComplete(() => settled = true),
        throwsStateError,
      );
      await pumpEventQueue();
      expect(settled, isTrue);
      await failing;

      constructed.single.completeLoad();
      await adding;
      expect(constructed.single.loadStyleCalls, isEmpty);
    });

    test(
        'two styles set while the layer loads both complete, and the last one shows',
        () async {
      final constructed = installFakeVectorTileLayers();
      final map = FakeMap();
      final view = FakeView(map).js;
      final layers = WebLayerController(mapId: 1);
      final adding = layers.addVectorTileLayer(
        layerId: 'counties',
        style: _mapStyle,
        view: view,
      );
      final counties = constructed.single;

      counties.failNextLoadStyle('AbortError');
      final overtaken = layers.setVectorTileStyle(
        layerId: 'counties',
        style: _satelliteStyle,
        view: view,
      );
      final last = layers.setVectorTileStyle(
        layerId: 'counties',
        style: _mapStyle,
        view: view,
      );
      await pumpEventQueue();
      expect(counties.loadStyleCalls, isEmpty);

      counties.completeLoad();
      await adding;
      await expectLater(overtaken, completes);
      await expectLater(last, completes);
      expect(counties.loadStyleCalls, [_satelliteStyle, _mapStyle]);
      expect(map.layerIds, ['counties']);
    });

    test(
        'a style set while a load that fails is pending throws that the layer '
        'is not found, and the failed layer is gone', () async {
      final constructed = installFakeVectorTileLayers();
      final map = FakeMap();
      final view = FakeView(map).js;
      final layers = WebLayerController(mapId: 1);
      final adding = layers.addVectorTileLayer(
        layerId: 'counties',
        style: _mapStyle,
        view: view,
      );
      final addingFails = expectLater(adding, throwsException);

      final swapping = layers.setVectorTileStyle(
        layerId: 'counties',
        style: _satelliteStyle,
        view: view,
      );
      final swappingFails = expectLater(swapping, _throwsNotFound('counties'));
      await pumpEventQueue();
      constructed.single.failLoad('request:server', 'Unauthorized');

      await addingFails;
      await swappingFails;
      expect(constructed.single.loadStyleCalls, isEmpty);
      expect(map.layerIds, isEmpty);
    });

    test('a style overtaken by the next one completes without error', () async {
      final map = FakeMap();
      final view = FakeView(map).js;
      final layers = WebLayerController(mapId: 1);
      final counties = await _addLoadedCounties(layers, view);

      counties.failNextLoadStyle('AbortError');
      final overtaken = layers.setVectorTileStyle(
        layerId: 'counties',
        style: _satelliteStyle,
        view: view,
      );
      final last = layers.setVectorTileStyle(
        layerId: 'counties',
        style: _mapStyle,
        view: view,
      );

      await expectLater(overtaken, completes);
      await expectLater(last, completes);
      expect(counties.loadStyleCalls, [_satelliteStyle, _mapStyle]);
      expect(map.layerIds, ['counties']);
    });

    test('a style that fails to load throws', () async {
      final view = FakeView(FakeMap()).js;
      final layers = WebLayerController(mapId: 1);
      final counties = await _addLoadedCounties(layers, view);

      counties.failNextLoadStyle('request:server');

      await expectLater(
        layers.setVectorTileStyle(
          layerId: 'counties',
          style: _satelliteStyle,
          view: view,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            allOf(contains('counties'), contains('request:server')),
          ),
        ),
      );
    });

    test('an unknown layer id throws', () async {
      final view = FakeView(FakeMap(layers: [FakeLayer(id: 'markers')])).js;
      final layers = WebLayerController(mapId: 1);

      await expectLater(
        layers.setVectorTileStyle(
          layerId: 'nothing',
          style: _satelliteStyle,
          view: view,
        ),
        _throwsNotFound('nothing'),
      );
      await expectLater(
        layers.setVectorTileStyle(
          layerId: 'markers',
          style: _satelliteStyle,
          view: view,
        ),
        _throwsNotFound('markers'),
      );
    });

    test('a layer removed from the map is not found', () async {
      final map = FakeMap();
      final view = FakeView(map).js;
      final layers = WebLayerController(mapId: 1);
      final counties = await _addLoadedCounties(layers, view);
      map.remove(counties.js);

      await expectLater(
        layers.setVectorTileStyle(
          layerId: 'counties',
          style: _satelliteStyle,
          view: view,
        ),
        _throwsNotFound('counties'),
      );
      expect(counties.loadStyleCalls, isEmpty);
    });
  });

  group('setLayerVisibility', () {
    test('hides and shows a layer of the map', () {
      final markers = FakeLayer(id: 'markers');
      final view = FakeView(FakeMap(layers: [markers])).js;
      final layers = WebLayerController(mapId: 1);

      layers.setLayerVisibility(layerId: 'markers', visible: false, view: view);
      expect(markers.visible, isFalse);

      layers.setLayerVisibility(layerId: 'markers', visible: true, view: view);
      expect(markers.visible, isTrue);
    });

    test('reaches a scene layer parked while the view is 2D', () async {
      final constructed = installFakeSceneLayers();
      final map = FakeMap();
      final view = FakeView(map).js;
      final layers = WebLayerController(mapId: 1);
      await layers.addSceneLayer(
        layerId: 'buildings',
        url: 'https://scene.test/SceneServer',
        options: SceneLayerOptions(
          symbol: const MeshSymbol3D(color: Color(0xFF888888)),
        ),
        view: view,
        isSceneViewActive: false,
      );
      expect(map.layerIds, isEmpty);

      layers.setLayerVisibility(
        layerId: 'buildings',
        visible: false,
        view: view,
      );

      expect(constructed.single.visible, isFalse);
    });

    test('an unknown layer id changes nothing', () {
      final markers = FakeLayer(id: 'markers');
      final view = FakeView(FakeMap(layers: [markers])).js;

      WebLayerController(mapId: 1)
          .setLayerVisibility(layerId: 'nothing', visible: false, view: view);

      expect(markers.visible, isTrue);
    });
  });
}
