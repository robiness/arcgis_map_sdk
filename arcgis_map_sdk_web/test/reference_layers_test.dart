@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/src/reference_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_arcgis.dart';

FakeLayer _labels(String id) => FakeLayer(id: id, type: 'vector-tile');

void main() {
  test(
      "a new basemap's labels go directly beneath the lowest graphics layer, above a layer at index 0",
      () async {
    final lightGrayLabels = _labels('light-gray labels');
    final hybridLabels = _labels('hybrid labels');
    final lightGray = FakeBasemap(loaded: true);
    final hybrid = FakeBasemap(referenceLayers: [hybridLabels]);
    final map = FakeMap(
      layers: [
        _labels('counties'),
        lightGrayLabels,
        FakeLayer(id: 'connections'),
        FakeLayer(id: 'markers'),
      ],
      basemap: hybrid,
    );

    final moved = await moveReferenceLayersBeneathGraphics(
      map.js,
      previous: (basemap: lightGray.js, layers: [lightGrayLabels.js].toJS),
    );

    expect(
      map.layerIds,
      ['counties', 'hybrid labels', 'connections', 'markers'],
    );
    expect(lightGray.referenceLayerIds, ['light-gray labels']);
    expect(hybrid.referenceLayerIds, isEmpty);
    expect(moved!.layers.toDart.map((layer) => layer.id), ['hybrid labels']);
    expect(moved.basemap.strictEquals(hybrid.js).toDart, isTrue);
  });

  test(
      "every basemap's labels sit beneath the graphics after a change away and back",
      () async {
    final lightGray = FakeBasemap(referenceLayers: [_labels('light-gray')]);
    final hybrid = FakeBasemap(referenceLayers: [_labels('hybrid')]);
    final map = FakeMap(
      layers: [_labels('counties'), FakeLayer(id: 'markers')],
      basemap: lightGray,
    );

    var moved = await moveReferenceLayersBeneathGraphics(map.js);
    expect(map.layerIds, ['counties', 'light-gray', 'markers']);

    map.basemap = hybrid.js;
    moved = await moveReferenceLayersBeneathGraphics(map.js, previous: moved);
    expect(map.layerIds, ['counties', 'hybrid', 'markers']);

    map.basemap = lightGray.js;
    await moveReferenceLayersBeneathGraphics(map.js, previous: moved);
    expect(map.layerIds, ['counties', 'light-gray', 'markers']);
    expect(hybrid.referenceLayerIds, ['hybrid']);
  });

  test('labels moved where the graphics layers are not yet go on top',
      () async {
    final emptyMapBasemap = FakeBasemap(referenceLayers: [_labels('labels')]);
    final emptyMap = FakeMap(basemap: emptyMapBasemap);

    await moveReferenceLayersBeneathGraphics(emptyMap.js);

    expect(emptyMap.layerIds, ['labels']);
    expect(emptyMapBasemap.loaded, isTrue);

    final map = FakeMap(
      layers: [_labels('counties')],
      basemap: FakeBasemap(referenceLayers: [_labels('labels')]),
    );

    await moveReferenceLayersBeneathGraphics(map.js);

    expect(map.layerIds, ['counties', 'labels']);
  });

  test(
      'labels below a layer that is not a graphics layer still end directly beneath the graphics',
      () async {
    final oldLabels = _labels('old labels');
    final oldBasemap = FakeBasemap(loaded: true);
    final map = FakeMap(
      layers: [oldLabels, _labels('counties'), FakeLayer(id: 'markers')],
      basemap: FakeBasemap(referenceLayers: [_labels('new labels')]),
    );

    await moveReferenceLayersBeneathGraphics(
      map.js,
      previous: (basemap: oldBasemap.js, layers: [oldLabels.js].toJS),
    );

    expect(map.layerIds, ['counties', 'new labels', 'markers']);
  });

  test('labels of a basemap replaced while it loaded stay with it', () async {
    final hybridLabels = _labels('hybrid labels');
    final lightGrayLabels = _labels('light-gray labels');
    final hybrid = FakeBasemap(referenceLayers: [hybridLabels]);
    final lightGray =
        FakeBasemap(referenceLayers: [lightGrayLabels], loaded: true);
    final map = FakeMap(layers: [FakeLayer(id: 'markers')], basemap: hybrid);
    final loading = hybrid.holdLoad();

    final replaced = moveReferenceLayersBeneathGraphics(map.js);
    map.basemap = lightGray.js;
    final current = await moveReferenceLayersBeneathGraphics(map.js);
    loading.complete();

    expect(await replaced, isNull);
    expect(map.layerIds, ['light-gray labels', 'markers']);
    expect(hybrid.referenceLayerIds, ['hybrid labels']);
    expect(
      current!.layers.toDart.map((layer) => layer.id),
      ['light-gray labels'],
    );
  });

  test('a basemap without labels moves nothing', () async {
    final oldLabels = _labels('old labels');
    final oldBasemap = FakeBasemap(loaded: true);
    final map = FakeMap(
      layers: [oldLabels, FakeLayer(id: 'markers')],
      basemap: FakeBasemap(),
    );

    final moved = await moveReferenceLayersBeneathGraphics(
      map.js,
      previous: (basemap: oldBasemap.js, layers: [oldLabels.js].toJS),
    );

    expect(moved, isNull);
    expect(map.layerIds, ['markers']);
    expect(oldBasemap.referenceLayerIds, ['old labels']);
  });
}
