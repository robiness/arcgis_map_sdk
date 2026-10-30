@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:arcgis_map_sdk_web/src/esri_request_interceptors.dart';
import 'package:flutter_test/flutter_test.dart';

const _api = 'https://api.test/';
const _boundaries = 'https://api.test/graphql/boundaries/';
const _elsewhere = 'https://elsewhere.test/';
const _countyTiles =
    'https://api.test/graphql/boundaries/county/VectorTileServer';

Future<Map<String, String>> _noHeaders() async => {};

List<JSObject> _interceptorsOf(JSObject requestConfig) =>
    (requestConfig['interceptors']! as JSArray<JSObject>).toDart;

List<String> _urlsOf(JSObject requestConfig) => [
      for (final interceptor in _interceptorsOf(requestConfig))
        (interceptor['urls']! as JSString).toDart,
    ];

JSObject _paramsWith(Map<String, Object?> requestOptions) =>
    {'url': _countyTiles, 'requestOptions': requestOptions}.jsify()!
        as JSObject;

Future<JSAny?> _runBefore(JSObject interceptor, JSObject params) =>
    ((interceptor['before']! as JSFunction).callAsFunction(null, params)!
            as JSPromise<JSAny?>)
        .toDart;

JSAny? _headersOf(JSObject params) =>
    (params['requestOptions']! as JSObject)['headers'];

void main() {
  test('the request waits for the headers and carries them beside its own',
      () async {
    final requestConfig = {'interceptors': <Object?>[]}.jsify()! as JSObject;
    final token = Completer<Map<String, String>>();
    EsriRequestInterceptors(requestConfig).set(
      urlPrefix: 'https://api.test/graphql/boundaries/',
      mapId: 1,
      headers: () => token.future,
    );
    final interceptor =
        (requestConfig['interceptors']! as JSArray<JSObject>).toDart.single;
    final params = {
      'url': 'https://api.test/graphql/boundaries/county/VectorTileServer',
      'requestOptions': {
        'headers': {'X-Own': '1'},
      },
    }.jsify()! as JSObject;

    var done = false;
    final before = ((interceptor['before']! as JSFunction)
            .callAsFunction(null, params)! as JSPromise<JSAny?>)
        .toDart
        .whenComplete(() => done = true);
    await pumpEventQueue();
    expect(done, isFalse);

    token.complete({'Authorization': 'Bearer t'});
    expect(await before, isNull);
    expect(
      ((params['requestOptions']! as JSObject)['headers']! as JSObject)
          .dartify(),
      {'X-Own': '1', 'Authorization': 'Bearer t'},
    );
    expect(
      (interceptor['urls']! as JSString).toDart,
      'https://api.test/graphql/boundaries/',
    );
  });

  group("beside the page's own interceptor", () {
    late JSObject requestConfig;
    late EsriRequestInterceptors interceptors;

    setUp(() {
      requestConfig = {
        'interceptors': [
          {'urls': _elsewhere},
        ],
      }.jsify()! as JSObject;
      interceptors = EsriRequestInterceptors(requestConfig);
    });

    test("each prefix becomes one interceptor ahead of the page's own", () {
      interceptors.set(urlPrefix: _api, mapId: 1, headers: _noHeaders);
      interceptors.set(urlPrefix: _boundaries, mapId: 1, headers: _noHeaders);

      expect(_urlsOf(requestConfig), [_boundaries, _api, _elsewhere]);
    });

    test('a second call for a prefix replaces its interceptor', () async {
      interceptors.set(
        urlPrefix: _boundaries,
        mapId: 1,
        headers: () async => {'Authorization': 'Bearer old'},
      );
      interceptors.set(
        urlPrefix: _boundaries,
        mapId: 1,
        headers: () async => {'Authorization': 'Bearer new'},
      );

      expect(_urlsOf(requestConfig), [_boundaries, _elsewhere]);
      final params = _paramsWith({});
      await _runBefore(_interceptorsOf(requestConfig).first, params);
      expect(
        (_headersOf(params)! as JSObject).dartify(),
        {'Authorization': 'Bearer new'},
      );
    });

    test('clearing a prefix removes its interceptor and leaves the others', () {
      interceptors.set(urlPrefix: _api, mapId: 1, headers: _noHeaders);
      interceptors.set(urlPrefix: _boundaries, mapId: 1, headers: _noHeaders);

      interceptors.clear(_boundaries);
      expect(_urlsOf(requestConfig), [_api, _elsewhere]);

      interceptors.clear(_api);
      expect(_urlsOf(requestConfig), [_elsewhere]);
    });

    test('a request without headers of its own gets them', () async {
      interceptors.set(
        urlPrefix: _boundaries,
        mapId: 1,
        headers: () async => {'Authorization': 'Bearer t'},
      );
      final params = _paramsWith({});

      await _runBefore(_interceptorsOf(requestConfig).first, params);

      expect(
        (_headersOf(params)! as JSObject).dartify(),
        {'Authorization': 'Bearer t'},
      );
    });

    test('a failing callback fails the request', () async {
      interceptors.set(
        urlPrefix: _boundaries,
        mapId: 1,
        headers: () => throw StateError('signed out'),
      );
      final params = _paramsWith({});

      await expectLater(
        _runBefore(_interceptorsOf(requestConfig).first, params),
        throwsA(
          isA<Object>()
              .having(
                (rejection) =>
                    (rejection as JSObject).instanceOfString('Error'),
                'is a JS Error',
                isTrue,
              )
              .having(
                (rejection) =>
                    ((rejection as JSObject)['message']! as JSString).toDart,
                'message',
                contains('signed out'),
              ),
        ),
      );

      expect(_headersOf(params), isNull);
    });
  });
}
