import 'package:arcgis_map_sdk_web/src/request_header_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const _api = 'https://api.test/';
const _boundaries = 'https://api.test/graphql/boundaries/';
const _tiles = 'https://tiles.test/';

Future<Map<String, String>> _noHeaders() async => {};

List<(String, int)> _prefixesAndMaps(RequestHeaderRules rules) =>
    [for (final rule in rules.rules) (rule.urlPrefix, rule.mapId)];

void main() {
  test('a second call for a prefix replaces the first', () {
    final rules = RequestHeaderRules();
    Future<Map<String, String>> first() async =>
        {'Authorization': 'Bearer old'};
    Future<Map<String, String>> second() async =>
        {'Authorization': 'Bearer new'};

    rules.set(
      urlPrefix: 'https://api.test/graphql/boundaries/',
      mapId: 1,
      headers: first,
    );
    rules.set(
      urlPrefix: 'https://api.test/graphql/boundaries/',
      mapId: 2,
      headers: second,
    );

    expect(rules.rules, hasLength(1));
    expect(rules.rules.single.mapId, 2);
    expect(identical(rules.rules.single.headers, second), isTrue);
  });

  test('the longest prefix comes first', () {
    final rules = RequestHeaderRules();

    rules.set(urlPrefix: _api, mapId: 1, headers: _noHeaders);
    rules.set(urlPrefix: _boundaries, mapId: 1, headers: _noHeaders);

    expect(
      [for (final rule in rules.rules) rule.urlPrefix],
      [_boundaries, _api],
    );
  });

  test(
      'clearing a prefix leaves the others; clearing an unknown one changes nothing',
      () {
    final rules = RequestHeaderRules();
    rules.set(urlPrefix: _boundaries, mapId: 1, headers: _noHeaders);
    rules.set(urlPrefix: _tiles, mapId: 1, headers: _noHeaders);

    rules.clear(_boundaries);
    expect(_prefixesAndMaps(rules), [(_tiles, 1)]);

    rules.clear('https://unknown.test/');
    expect(_prefixesAndMaps(rules), [(_tiles, 1)]);
  });

  test('disposing a map removes only the prefixes it set last', () {
    final rules = RequestHeaderRules();
    rules.set(urlPrefix: _boundaries, mapId: 1, headers: _noHeaders);
    rules.set(urlPrefix: _tiles, mapId: 1, headers: _noHeaders);
    rules.set(urlPrefix: _tiles, mapId: 2, headers: _noHeaders);

    rules.clearMap(1);

    expect(_prefixesAndMaps(rules), [(_tiles, 2)]);
  });

  test('a recreated map keeps its headers whichever map is disposed first', () {
    final disposedAfter = RequestHeaderRules();
    disposedAfter.set(urlPrefix: _boundaries, mapId: 1, headers: _noHeaders);
    disposedAfter.set(urlPrefix: _boundaries, mapId: 2, headers: _noHeaders);
    disposedAfter.clearMap(1);
    expect(_prefixesAndMaps(disposedAfter), [(_boundaries, 2)]);

    final disposedBefore = RequestHeaderRules();
    disposedBefore.set(urlPrefix: _boundaries, mapId: 1, headers: _noHeaders);
    disposedBefore.clearMap(1);
    disposedBefore.set(urlPrefix: _boundaries, mapId: 2, headers: _noHeaders);
    expect(_prefixesAndMaps(disposedBefore), [(_boundaries, 2)]);
  });

  test('a prefix must be an absolute http or https URL', () {
    final rules = RequestHeaderRules();

    for (final prefix in [
      '',
      'graphql/boundaries/',
      '//api.test/',
      'ftp://api.test/',
    ]) {
      expect(
        () => rules.set(urlPrefix: prefix, mapId: 1, headers: _noHeaders),
        throwsArgumentError,
        reason: prefix,
      );
    }
    rules.set(
      urlPrefix: 'http://localhost:8765/boundaries/',
      mapId: 1,
      headers: _noHeaders,
    );

    expect(_prefixesAndMaps(rules), [('http://localhost:8765/boundaries/', 1)]);
  });
}
