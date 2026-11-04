@TestOn('browser')
library;

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/src/web_stream_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_arcgis.dart';

void main() {
  late FakeView view;
  late WebStreamManager manager;

  setUp(() {
    view = FakeView(FakeMap())
      ..mapPointAt =
          (x, y) => (latitude: 53 + y / 1000, longitude: -6 + x / 1000);
    manager = WebStreamManager(mapId: 1);
  });
  tearDown(() => manager.dispose());

  test('a pointer move carries its position, time, buttons and map point',
      () async {
    final moves = manager.pointerMoveStream(view.js).take(1).toList();
    view.emit('pointer-move',
        pointerEvent(x: 120, y: 80, buttons: 1, timeStamp: 1234.5));
    expect(await moves, [
      const MapPointerMove(
          x: 120,
          y: 80,
          timeStamp: 1234.5,
          buttons: 1,
          mapPoint: LatLng(53.08, -5.88),
          overMap: true),
    ]);
    expect(view.toMapCalls, [(x: 120.0, y: 80.0)]);
  });

  test(
      'leaving the view is a move that is not over the map and has no map point',
      () async {
    final moves = manager.pointerMoveStream(view.js).take(1).toList();
    view.emit('pointer-leave', pointerEvent(x: 300, y: 5, timeStamp: 2000));
    expect(await moves, [
      const MapPointerMove(
          x: 300,
          y: 5,
          timeStamp: 2000,
          buttons: 0,
          mapPoint: null,
          overMap: false),
    ]);
    expect(view.toMapCalls, isEmpty);
  });

  test(
      'a point the view cannot place on the map is over it without a map point',
      () async {
    view.mapPointAt = (x, y) => null;
    final moves = manager.pointerMoveStream(view.js).take(1).toList();
    view.emit('pointer-move', pointerEvent(x: 10, y: 10));
    expect(
        (await moves).single,
        const MapPointerMove(
            x: 10,
            y: 10,
            timeStamp: 0,
            buttons: 0,
            mapPoint: null,
            overMap: true));
  });

  test(
      'the view gets one handler pair however many listen, and every listener every move',
      () async {
    final first = manager.pointerMoveStream(view.js).take(2).toList();
    final second = manager.pointerMoveStream(view.js).take(2).toList();
    view
      ..emit('pointer-move', pointerEvent(x: 1, y: 1))
      ..emit('pointer-move', pointerEvent(x: 2, y: 2));
    expect((await first).map((m) => m.x), [1, 2]);
    expect((await second).map((m) => m.x), [1, 2]);
    expect(view.handlersFor('pointer-move'), hasLength(1));
    expect(view.handlersFor('pointer-leave'), hasLength(1));
  });

  test('the moves follow the view across a switch between 2D and 3D', () async {
    final scene = FakeView(FakeMap())
      ..mapPointAt = (x, y) => (latitude: 52, longitude: -7);
    final moves = manager.pointerMoveStream(view.js).take(1).toList();
    manager.switchView(scene.js);
    view.emit('pointer-move', pointerEvent(x: 1, y: 1));
    scene.emit('pointer-move', pointerEvent(x: 5, y: 5));
    expect((await moves).single.mapPoint, const LatLng(52, -7));
    expect(view.handlersFor('pointer-move'), isEmpty);
    expect(scene.handlersFor('pointer-move'), hasLength(1));
  });
}
