@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:arcgis_map_sdk_web/src/basemap_style_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_arcgis.dart';

const _lineId = 'administrative boundary/level 6/line';
const _labelId = 'administrative label/county level 6';

void main() {
  test(
      'hides the named style layers in base and reference layers alike, skipping ids a layer lacks',
      () async {
    final base = FakeVectorTileLayer(
      id: 'base',
      styleLayerIds: {_lineId, 'water'},
    );
    final labels = FakeVectorTileLayer(id: 'labels', styleLayerIds: {_labelId});

    await BasemapStyleLayers().setVisible(
      [_lineId, _labelId],
      visible: false,
      layers: Future.value([base.js, labels.js]),
    );

    expect(base.visibility, {_lineId: 'none'});
    expect(labels.visibility, {_labelId: 'none'});
  });

  test('leaves layers that are not vector tile layers alone', () async {
    final imagery = FakeLayer(id: 'imagery', type: 'tile');
    final base = FakeVectorTileLayer(id: 'base', styleLayerIds: {_lineId});

    await BasemapStyleLayers().setVisible(
      [_lineId],
      visible: false,
      layers: Future.value([imagery.js, base.js]),
    );

    expect(imagery.loadCount, 0);
    expect(base.visibility, {_lineId: 'none'});
  });

  test('waits for a layer to load before changing it', () async {
    final base = FakeVectorTileLayer(id: 'base', styleLayerIds: {_lineId});
    final loading = base.holdLoad();

    final done = BasemapStyleLayers().setVisible(
      [_lineId],
      visible: false,
      layers: Future.value([base.js]),
    );
    await pumpEventQueue();

    expect(base.visibility, isEmpty);

    loading.complete();
    await done;

    expect(base.visibility, {_lineId: 'none'});
  });

  test('a later call for an id wins, and shown ids stay recorded', () async {
    final styles = BasemapStyleLayers();
    await styles.setVisible(
      ['a', 'b'],
      visible: false,
      layers: Future.value(const []),
    );
    await styles.setVisible(
      ['a'],
      visible: true,
      layers: Future.value(const []),
    );

    final fresh = FakeVectorTileLayer(id: 'fresh', styleLayerIds: {'a', 'b'});
    await styles.applyTo([fresh.js]);

    expect(fresh.visibility, {'a': 'visible', 'b': 'none'});
  });

  test('a returning basemap gets what was set while it was away', () async {
    final lightGray = FakeVectorTileLayer(
      id: 'light-gray',
      styleLayerIds: {_lineId, _labelId},
    );
    final hybrid = FakeVectorTileLayer(id: 'hybrid', styleLayerIds: {_labelId});
    final styles = BasemapStyleLayers();

    await styles.setVisible(
      [_lineId, _labelId],
      visible: false,
      layers: Future.value([lightGray.js]),
    );
    await styles.applyTo([hybrid.js]);
    await styles.setVisible(
      [_lineId, _labelId],
      visible: true,
      layers: Future.value([hybrid.js]),
    );
    await styles.applyTo([lightGray.js]);

    expect(hybrid.visibility, {_labelId: 'visible'});
    expect(lightGray.visibility, {_lineId: 'visible', _labelId: 'visible'});
  });

  test('a layer that fails to load is skipped', () async {
    final failing = FakeVectorTileLayer(
      id: 'failing',
      styleLayerIds: {_lineId},
      failsToLoad: true,
    );
    final base = FakeVectorTileLayer(id: 'base', styleLayerIds: {_lineId});

    await BasemapStyleLayers().setVisible(
      [_lineId],
      visible: false,
      layers: Future.value([failing.js, base.js]),
    );

    expect(failing.visibility, isEmpty);
    expect(base.visibility, {_lineId: 'none'});
  });

  test('a call is kept before the current basemap has loaded', () async {
    final styles = BasemapStyleLayers();
    final loading = Completer<List<JsLayer>>();
    final done = styles.setVisible(
      [_lineId],
      visible: false,
      layers: loading.future,
    );

    final fresh = FakeVectorTileLayer(
      id: 'fresh',
      styleLayerIds: {_lineId, 'water'},
    );
    await styles.applyTo([fresh.js]);

    expect(fresh.visibility, {_lineId: 'none'});

    loading.complete(const []);
    await done;
  });

  test('a later call wins even when an earlier one waits on a loading basemap',
      () async {
    final styles = BasemapStyleLayers();
    final loading = Completer<List<JsLayer>>();
    final hidden = styles.setVisible(
      [_lineId],
      visible: false,
      layers: loading.future,
    );
    await styles.setVisible(
      [_lineId],
      visible: true,
      layers: Future.value(const []),
    );

    final loaded = FakeVectorTileLayer(id: 'loaded', styleLayerIds: {_lineId});
    loading.complete([loaded.js]);
    await hidden;

    final fresh = FakeVectorTileLayer(id: 'fresh', styleLayerIds: {_lineId});
    await styles.applyTo([fresh.js]);

    expect(loaded.visibility, {_lineId: 'visible'});
    expect(fresh.visibility, {_lineId: 'visible'});
  });

  test('a call is kept when the current basemap fails to load', () async {
    final styles = BasemapStyleLayers();

    await expectLater(
      styles.setVisible(
        [_lineId],
        visible: false,
        layers: Future.error(StateError('offline')),
      ),
      throwsStateError,
    );

    final fresh = FakeVectorTileLayer(id: 'fresh', styleLayerIds: {_lineId});
    await styles.applyTo([fresh.js]);

    expect(fresh.visibility, {_lineId: 'none'});
  });

  test(
      "basemap layers are the basemap's own and the labels moved beneath the graphics",
      () async {
    final base = FakeLayer(id: 'base', type: 'vector-tile');
    final reference = FakeLayer(id: 'reference', type: 'vector-tile');
    final moved = FakeLayer(id: 'moved', type: 'vector-tile');
    final basemap = FakeBasemap(
      baseLayers: [base],
      referenceLayers: [reference],
    );

    final layers = await basemapLayers(
      basemap.js,
      movedReferenceLayers: [moved.js].toJS,
    );

    expect(basemap.loaded, isTrue);
    expect(layers.map((layer) => layer.id), ['base', 'reference', 'moved']);
  });
}
