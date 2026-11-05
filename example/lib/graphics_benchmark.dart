// Measures how long the web plugin takes to add and remove many graphics.
//
// Build and serve with dart2js, as only its numbers mean anything:
//   flutter build web --release -t lib/graphics_benchmark.dart -o build/bench
//   python3 -m http.server -d build/bench 8090
// `?reps=` sets the repetitions per scenario, `?only=` runs the scenarios
// whose name contains it.
// The results show on the page and in `window.benchResults`.
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';

import 'package:arcgis_example/main.dart' show arcGisApiKey;
import 'package:arcgis_map_sdk/arcgis_map_sdk.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: GraphicsBenchmarkPage()));

const _layerId = 'bench';
const _base = 2000;

final _reps = int.tryParse(Uri.base.queryParameters['reps'] ?? '') ?? 5;

final _only = Uri.base.queryParameters['only'] ?? '';

class GraphicsBenchmarkPage extends StatefulWidget {
  const GraphicsBenchmarkPage({super.key});

  @override
  State<GraphicsBenchmarkPage> createState() => _GraphicsBenchmarkPageState();
}

class _GraphicsBenchmarkPageState extends State<GraphicsBenchmarkPage> {
  late ArcgisMapController _map;
  final _random = Random(42);
  final _lines = <String>[];
  final _results = <Map<String, Object?>>[];
  JSObject? _layerView;

  Future<void> _onMapCreated(ArcgisMapController controller) async {
    _map = controller;
    await controller.addGraphicsLayer(
      layerId: _layerId,
      options: GraphicsLayerOptions(fields: const []),
    );
    await _findLayerView();
    await Future<void>.delayed(const Duration(seconds: 3));
    await _settle();
    await _run();
  }

  Future<void> _findLayerView() async {
    final loader = globalContext['\$arcgis']! as JSObject;
    final module = await loader
        .callMethod<JSPromise<JSObject>>(
            'import'.toJS, '@arcgis/core/views/View.js'.toJS)
        .toDart;
    // Only views that are ready are among them.
    final views = module['views']! as JSObject;
    while ((views['length']! as JSNumber).toDartInt == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    final view = views.callMethod<JSObject>('getItemAt'.toJS, 0.toJS);
    _log('view ready');
    final map = view['map']! as JSObject;
    final layer = map.callMethod<JSObject>('findLayerById'.toJS, _layerId.toJS);
    _layerView = await view
        .callMethod<JSPromise<JSObject>>('whenLayerView'.toJS, layer)
        .toDart;
  }

  static double _now() => (globalContext['performance']! as JSObject)
      .callMethod<JSNumber>('now'.toJS)
      .toDartDouble;

  static Future<double> _frame() {
    final completer = Completer<double>();
    (globalContext['window']! as JSObject).callMethod(
      'requestAnimationFrame'.toJS,
      ((JSNumber time) => completer.complete(time.toDartDouble)).toJS,
    );
    return completer.future;
  }

  bool get _updating =>
      (_layerView!['updating'] as JSBoolean?)?.toDart ?? false;

  /// Waits until the layer view has drawn what changed, and returns the
  /// longest gap between two frames on the way.
  Future<({double settled, double longestFrame})> _settle(
      [double? start]) async {
    final from = start ?? _now();
    var last = await _frame();
    var longest = last - from;
    var idle = 0;
    var frames = 0;
    while (idle < 3 && _now() - from < 10000) {
      final time = await _frame();
      longest = max(longest, time - last);
      last = time;
      frames++;
      idle = (!_updating && frames > 2) ? idle + 1 : 0;
    }
    return (settled: _now() - from, longestFrame: longest);
  }

  PointGraphic _graphic(String id) => PointGraphic(
        latitude: 51.5 + _random.nextDouble() * 3.8,
        longitude: -10.4 + _random.nextDouble() * 4.4,
        attributes: Attributes({'id': id, 'family': 'pin'}),
        symbol: PictureMarkerSymbol(
          assetUri: 'assets/assets/pin_filled.svg',
          width: 22,
          height: 32,
          yOffset: 16,
        ),
      );

  List<String> _ids(String prefix, int count) =>
      [for (var i = 0; i < count; i++) '$prefix$i'];

  /// [count] ids of the base layer, spread over it as the graphics are that
  /// leave a map's view.
  List<String> _spreadIds(int count) =>
      (_ids('g', _base)..shuffle(Random(7))).take(count).toList();

  Future<void> _reset({int count = _base}) async {
    _map.removeGraphics(layerId: _layerId);
    for (final id in _ids('g', count)) {
      _map.addGraphic(layerId: _layerId, graphic: _graphic(id));
    }
    await _settle();
  }

  Future<void> _measure(
    String name, {
    required FutureOr<void> Function() setUp,
    required void Function() run,
  }) async {
    if (!name.contains(_only)) return;
    final calls = <double>[];
    final settled = <double>[];
    final frames = <double>[];
    for (var rep = 0; rep < _reps; rep++) {
      await setUp();
      final start = _now();
      run();
      calls.add(_now() - start);
      final settle = await _settle(start);
      settled.add(settle.settled);
      frames.add(settle.longestFrame);
    }
    final result = {
      'name': name,
      'callsMs': _median(calls),
      'settledMs': _median(settled),
      'longestFrameMs': _median(frames),
      'callsMsAll': calls.map(_round).toList(),
    };
    _results.add(result);
    _log('$name: calls ${_round(_median(calls))} ms, settled '
        '${_round(_median(settled))} ms, longest frame '
        '${_round(_median(frames))} ms  (calls ${result['callsMsAll']})');
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }

  static double _round(double value) => (value * 10).round() / 10;

  void _log(String line) {
    setState(() => _lines.add(line));
    (globalContext['console']! as JSObject)
        .callMethod('log'.toJS, '[bench] $line'.toJS);
  }

  Future<void> _run() async {
    _log('base layer: $_base graphics, $_reps reps, median');

    await _measure(
      'add 2000, one call each',
      setUp: () => _reset(count: 0),
      run: () {
        for (final id in _ids('g', 2000)) {
          _map.addGraphic(layerId: _layerId, graphic: _graphic(id));
        }
      },
    );
    await _measure(
      'regroup: add 1200 + remove 700, one call each',
      setUp: _reset,
      run: () {
        for (final id in _ids('h', 1200)) {
          _map.addGraphic(layerId: _layerId, graphic: _graphic(id));
        }
        for (final id in _spreadIds(700)) {
          _map.removeGraphic(layerId: _layerId, objectId: id);
        }
      },
    );
    await _measure(
      'remove 1000, one call each',
      setUp: _reset,
      run: () {
        for (final id in _spreadIds(1000)) {
          _map.removeGraphic(layerId: _layerId, objectId: id);
        }
      },
    );
    await _measure(
      'removeGraphics family, excluding 1000 ids',
      setUp: _reset,
      run: () => _map.removeGraphics(
        layerId: _layerId,
        removeByAttributeKey: 'family',
        removeByAttributeValue: 'pin',
        excludeAttributeKey: 'id',
        excludeAttributeValues: _spreadIds(1000),
      ),
    );
    await _measure(
      'updateGraphicSymbol x100',
      setUp: _reset,
      run: () {
        for (final id in _ids('g', 100)) {
          _map.updateGraphicSymbol(
            layerId: _layerId,
            graphicId: id,
            symbol: PictureMarkerSymbol(
              assetUri: 'assets/assets/pin_filled.svg',
              width: 32,
              height: 32,
              yOffset: 16,
            ),
          );
        }
      },
    );
    await _measure(
      'add 2000, one addGraphics',
      setUp: () => _reset(count: 0),
      run: () => _map.addGraphics(
        layerId: _layerId,
        graphics: [for (final id in _ids('g', 2000)) _graphic(id)],
      ),
    );
    await _measure(
      'regroup: addGraphics 1200 + removeGraphicsById 700',
      setUp: _reset,
      run: () {
        _map.addGraphics(
          layerId: _layerId,
          graphics: [for (final id in _ids('h', 1200)) _graphic(id)],
        );
        _map.removeGraphicsById(layerId: _layerId, graphicIds: _spreadIds(700));
      },
    );
    await _measure(
      'remove 1000, one removeGraphicsById',
      setUp: _reset,
      run: () => _map.removeGraphicsById(
          layerId: _layerId, graphicIds: _spreadIds(1000)),
    );

    globalContext['benchResults'] = jsonEncode(_results).toJS;
    _log('done');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: ArcgisMap(
              mapStyle: MapStyle.twoD,
              apiKey: arcGisApiKey,
              basemap: BaseMap.arcgisStreets,
              initialCenter: const LatLng(53.4, -8.0),
              zoom: 7,
              onMapCreated: _onMapCreated,
            ),
          ),
          SizedBox(
            width: 520,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final line in _lines)
                  Text(line, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
