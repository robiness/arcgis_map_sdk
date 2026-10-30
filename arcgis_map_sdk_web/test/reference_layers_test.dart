@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/src/reference_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_arcgis.dart';

FakeLayer _labels(String id) => FakeLayer(id: id, type: 'vector-tile');

/// A holder of [labels], moved into a map from [basemap].
MovedReferenceLayersHolder _moved(FakeBasemap basemap, List<FakeLayer> labels) {
  return MovedReferenceLayersHolder()
    ..current = (
      basemap: basemap.js,
      layers: [for (final layer in labels) layer.js].toJS,
    );
}

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
    final moved = _moved(lightGray, [lightGrayLabels]);

    await moveReferenceLayersBeneathGraphics(map.js, moved);

    expect(
      map.layerIds,
      ['counties', 'hybrid labels', 'connections', 'markers'],
    );
    expect(lightGray.referenceLayerIds, ['light-gray labels']);
    expect(hybrid.referenceLayerIds, isEmpty);
    expect(
      moved.current!.layers.toDart.map((layer) => layer.id),
      ['hybrid labels'],
    );
    expect(moved.current!.basemap.strictEquals(hybrid.js).toDart, isTrue);
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
    final moved = MovedReferenceLayersHolder();

    await moveReferenceLayersBeneathGraphics(map.js, moved);
    expect(map.layerIds, ['counties', 'light-gray', 'markers']);

    map.basemap = hybrid.js;
    await moveReferenceLayersBeneathGraphics(map.js, moved);
    expect(map.layerIds, ['counties', 'hybrid', 'markers']);

    map.basemap = lightGray.js;
    await moveReferenceLayersBeneathGraphics(map.js, moved);
    expect(map.layerIds, ['counties', 'light-gray', 'markers']);
    expect(hybrid.referenceLayerIds, ['hybrid']);
  });

  test(
      "two basemap changes in one task leave only the last basemap's labels in the map",
      () async {
    final lightGray = FakeBasemap(
      referenceLayers: [_labels('light-gray labels')],
      loaded: true,
    );
    final hybrid = FakeBasemap(
      referenceLayers: [_labels('hybrid detail')],
      loaded: true,
    );
    final map = FakeMap(
      layers: [_labels('counties'), FakeLayer(id: 'pins')],
      basemap: lightGray,
    );
    final moved = MovedReferenceLayersHolder();
    await moveReferenceLayersBeneathGraphics(map.js, moved);

    map.basemap = hybrid.js;
    final toHybrid = moveReferenceLayersBeneathGraphics(map.js, moved);
    map.basemap = lightGray.js;
    final back = moveReferenceLayersBeneathGraphics(map.js, moved);
    await Future.wait([toHybrid, back]);

    expect(map.layerIds, ['counties', 'light-gray labels', 'pins']);
    expect(hybrid.referenceLayerIds, ['hybrid detail']);
    expect(moved.current!.basemap.strictEquals(lightGray.js).toDart, isTrue);
    expect(
      moved.current!.layers.toDart.map((layer) => layer.id),
      ['light-gray labels'],
    );
  });

  test('labels moved where the graphics layers are not yet go on top',
      () async {
    final emptyMapBasemap = FakeBasemap(referenceLayers: [_labels('labels')]);
    final emptyMap = FakeMap(basemap: emptyMapBasemap);

    await moveReferenceLayersBeneathGraphics(
      emptyMap.js,
      MovedReferenceLayersHolder(),
    );

    expect(emptyMap.layerIds, ['labels']);
    expect(emptyMapBasemap.loaded, isTrue);

    final map = FakeMap(
      layers: [_labels('counties')],
      basemap: FakeBasemap(referenceLayers: [_labels('labels')]),
    );

    await moveReferenceLayersBeneathGraphics(
      map.js,
      MovedReferenceLayersHolder(),
    );

    expect(map.layerIds, ['counties', 'labels']);
  });

  test(
      'labels below a layer that is not a graphics layer still end directly beneath the graphics',
      () async {
    final oldLabels = _labels('old labels');
    final map = FakeMap(
      layers: [oldLabels, _labels('counties'), FakeLayer(id: 'markers')],
      basemap: FakeBasemap(referenceLayers: [_labels('new labels')]),
    );

    await moveReferenceLayersBeneathGraphics(
      map.js,
      _moved(FakeBasemap(loaded: true), [oldLabels]),
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
    final moved = MovedReferenceLayersHolder();
    final loading = hybrid.holdLoad();

    final replaced = moveReferenceLayersBeneathGraphics(map.js, moved);
    map.basemap = lightGray.js;
    await moveReferenceLayersBeneathGraphics(map.js, moved);
    loading.complete();
    await replaced;

    expect(map.layerIds, ['light-gray labels', 'markers']);
    expect(hybrid.referenceLayerIds, ['hybrid labels']);
    expect(moved.current!.basemap.strictEquals(lightGray.js).toDart, isTrue);
    expect(
      moved.current!.layers.toDart.map((layer) => layer.id),
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
    final moved = _moved(oldBasemap, [oldLabels]);

    await moveReferenceLayersBeneathGraphics(map.js, moved);

    expect(moved.current, isNull);
    expect(map.layerIds, ['markers']);
    expect(oldBasemap.referenceLayerIds, ['old labels']);
  });
}
