@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:ui';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:arcgis_map_sdk_web/src/web_layer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_arcgis.dart';

PointGraphic _graphic(String id, {String family = 'pin', double size = 4}) {
  return PointGraphic(
    latitude: 53.35,
    longitude: -6.26,
    attributes: Attributes({'id': id, 'family': family}),
    symbol: SimpleMarkerSymbol(
      color: const Color(0xFFE60000),
      outlineColor: const Color(0xFFFFFFFF),
      radius: size.round(),
    ),
  );
}

List<PointGraphic> _graphics(Iterable<String> ids) => [
      for (final id in ids) _graphic(id),
    ];

JsGraphic _jsGraphic(String id) {
  return {
    'attributes': {'id': id},
  }.jsify()! as JsGraphic;
}

typedef _Setup = ({
  WebLayerController layers,
  JsView view,
  FakeGraphicsLayer pins,
});

/// A controller with the graphics layer `pins`, added through it.
Future<_Setup> _withPins({FakeMap? map}) async {
  final constructed = installFakeGraphicsLayers();
  installFakeGraphics();
  final view = FakeView(map ?? FakeMap()).js;
  final layers = WebLayerController(mapId: 1);
  await layers.addGraphicsLayer(
    layerId: 'pins',
    options: GraphicsLayerOptions(fields: const []),
    view: view,
  );
  return (layers: layers, view: view, pins: constructed.last);
}

void main() {
  group('addGraphics', () {
    test('adds the graphics in one call, in their order', () async {
      final (:layers, :view, :pins) = await _withPins();

      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(['b', 'a', 'c']),
        view: view,
      );

      expect(pins.graphicIds, ['b', 'a', 'c']);
      expect(pins.calls, ['addMany']);
    });

    test('with no graphics leaves the layer alone', () async {
      final (:layers, :view, :pins) = await _withPins();

      await layers.addGraphics(layerId: 'pins', graphics: [], view: view);

      expect(pins.calls, isEmpty);
    });

    test('into a layer the map lacks fails', () async {
      final (:layers, :view, pins: _) = await _withPins();

      await expectLater(
        layers.addGraphics(
          layerId: 'nothing',
          graphics: _graphics(['a']),
          view: view,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('removeGraphicsById', () {
    test('removes the graphics with the ids in one call', () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(['a', 'b', 'c', 'd']),
        view: view,
      );

      layers.removeGraphicsById(
        layerId: 'pins',
        graphicIds: ['d', 'b'],
        view: view,
      );

      expect(pins.graphicIds, ['a', 'c']);
      expect(pins.calls, ['addMany', 'removeMany']);
    });

    test('skips ids the layer lacks', () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(['a', 'b']),
        view: view,
      );

      layers.removeGraphicsById(
        layerId: 'pins',
        graphicIds: ['x', 'a', 'a'],
        view: view,
      );
      layers.removeGraphicsById(
        layerId: 'pins',
        graphicIds: ['y'],
        view: view,
      );

      expect(pins.graphicIds, ['b']);
      expect(pins.calls, ['addMany', 'removeMany']);
    });

    test('from a layer that is missing or not a graphics layer fails', () {
      final view = FakeView(
        FakeMap(layers: [FakeLayer(id: 'sites', type: 'feature')]),
      ).js;
      final layers = WebLayerController(mapId: 1);

      for (final layerId in ['sites', 'nothing']) {
        expect(
          () => layers.removeGraphicsById(
            layerId: layerId,
            graphicIds: ['a'],
            view: view,
          ),
          throwsA(isA<Exception>()),
        );
      }
    });
  });

  group('removeGraphic', () {
    test('removes the graphic with the id', () async {
      final (:layers, :view, :pins) = await _withPins();
      for (final id in ['a', 'b', 'c']) {
        await layers.addGraphic(
          layerId: 'pins',
          graphic: _graphic(id),
          view: view,
        );
      }

      await layers.removeGraphic(layerId: 'pins', objectId: 'b', view: view);

      expect(pins.graphicIds, ['a', 'c']);
    });

    test('finds each graphic without going through the layer', () async {
      final (:layers, :view, :pins) = await _withPins();
      final ids = [for (var i = 0; i < 100; i++) 'g$i'];
      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(ids),
        view: view,
      );
      final throughBefore = pins.toArrayCount;

      for (final id in ids.take(50)) {
        await layers.removeGraphic(layerId: 'pins', objectId: id, view: view);
      }
      layers.removeGraphicsById(
        layerId: 'pins',
        graphicIds: ids.skip(50).take(25),
        view: view,
      );

      expect(pins.graphicIds, ids.skip(75));
      expect(pins.toArrayCount, throughBefore);
    });

    test('finds a graphic put into the layer directly', () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphic(
        layerId: 'pins',
        graphic: _graphic('a'),
        view: view,
      );
      pins.addDirectly(_jsGraphic('b'));

      await layers.removeGraphic(layerId: 'pins', objectId: 'b', view: view);

      expect(pins.graphicIds, ['a']);
    });

    test('takes a graphic that left the layer directly for gone', () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(['a', 'b']),
        view: view,
      );
      pins.removeDirectly('a');
      pins.calls.clear();

      await layers.removeGraphic(layerId: 'pins', objectId: 'a', view: view);

      expect(pins.graphicIds, ['b']);
      expect(pins.calls, isEmpty);
    });

    test('removes a graphic added again after it left the layer directly',
        () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphic(
        layerId: 'pins',
        graphic: _graphic('a'),
        view: view,
      );
      pins.removeDirectly('a');
      await layers.addGraphic(
        layerId: 'pins',
        graphic: _graphic('a'),
        view: view,
      );

      await layers.removeGraphic(layerId: 'pins', objectId: 'a', view: view);

      expect(pins.graphicIds, isEmpty);
    });

    test('of graphics sharing an id removes the first, then the next',
        () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphics(
        layerId: 'pins',
        graphics: [
          _graphic('a', family: 'first'),
          _graphic('b'),
          _graphic('a', family: 'second'),
        ],
        view: view,
      );

      await layers.removeGraphic(layerId: 'pins', objectId: 'a', view: view);
      final families = [
        for (final graphic in pins.graphics.toArray().toDart)
          (graphic.attributes!['family']! as JSString).toDart,
      ];
      await layers.removeGraphic(layerId: 'pins', objectId: 'a', view: view);

      expect(families, ['pin', 'second']);
      expect(pins.graphicIds, ['b']);
    });

    test('goes to the layer that took the id of a removed one', () async {
      final map = FakeMap();
      final (:layers, :view, pins: first) = await _withPins(map: map);
      await layers.addGraphic(
        layerId: 'pins',
        graphic: _graphic('a'),
        view: view,
      );
      map.remove(first.js);
      final (layers: _, view: _, pins: second) = await _withPins(map: map);
      // The layer the controller added before is gone; a second controller
      // added its successor, so this controller has never seen it.
      second.addDirectly(_jsGraphic('a'));

      await layers.addGraphic(
        layerId: 'pins',
        graphic: _graphic('b'),
        view: view,
      );
      await layers.removeGraphic(layerId: 'pins', objectId: 'a', view: view);

      expect(first.graphicIds, ['a']);
      expect(second.graphicIds, ['b']);
    });
  });

  group('removeGraphics', () {
    test('removes the family except the excluded ids, in one call', () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphics(
        layerId: 'pins',
        graphics: [
          ..._graphics(['a', 'b', 'c', 'd']),
          _graphic('label', family: 'label'),
        ],
        view: view,
      );

      layers.removeGraphics(
        layerId: 'pins',
        removeByAttributeKey: 'family',
        removeByAttributeValue: 'pin',
        excludeAttributeKey: 'id',
        excludeAttributeValues: ['c', 'a', 'x'],
        view: view,
      );

      expect(pins.graphicIds, ['a', 'c', 'label']);
      expect(pins.calls, ['addMany', 'removeMany']);
    });

    test('without a key removes every graphic with attributes', () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(['a', 'b']),
        view: view,
      );
      pins.addDirectly(JSObject() as JsGraphic);

      layers.removeGraphics(layerId: 'pins', view: view);

      expect(pins.graphicIds, [null]);
    });

    test('without a layer id removes from every graphics layer', () async {
      final labels = FakeGraphicsLayer(id: 'labels');
      final (:layers, :view, :pins) =
          await _withPins(map: FakeMap(layers: [labels]));
      labels.addDirectly(_jsGraphic('l'));
      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(['a', 'b']),
        view: view,
      );

      layers.removeGraphics(view: view);

      expect(pins.graphicIds, isEmpty);
      expect(labels.graphicIds, isEmpty);
    });

    test('forgets what it removed, so the ids can come back', () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(['a', 'b']),
        view: view,
      );
      layers.removeGraphics(
        layerId: 'pins',
        removeByAttributeKey: 'family',
        removeByAttributeValue: 'pin',
        view: view,
      );
      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(['a']),
        view: view,
      );
      final throughBefore = pins.toArrayCount;

      layers.removeGraphicsById(
        layerId: 'pins',
        graphicIds: ['a'],
        view: view,
      );

      expect(pins.graphicIds, isEmpty);
      expect(pins.toArrayCount, throughBefore);
    });
  });

  group('updateGraphicSymbol', () {
    test('gives the graphic with the id the symbol', () async {
      final (:layers, :view, :pins) = await _withPins();
      await layers.addGraphics(
        layerId: 'pins',
        graphics: _graphics(['a', 'b']),
        view: view,
      );

      layers.updateGraphicSymbol(
        layerId: 'pins',
        graphicId: 'b',
        symbol: _graphic('b', size: 9).symbol,
        view: view,
        isSceneView: false,
      );

      final sizes = [
        for (final graphic in pins.graphics.toArray().toDart)
          (graphic.symbol!['size']! as JSNumber).toDartDouble,
      ];
      expect(sizes, [4, 9]);
    });
  });
}
