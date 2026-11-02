import 'dart:developer' as developer;
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:arcgis_map_sdk_web/src/request_header_rules.dart';

/// Keeps the interceptors of [requestConfig], which is `esriConfig.request`,
/// in line with the page's [RequestHeaderRules]: one interceptor per rule,
/// ahead of the interceptors the page has of its own.
class EsriRequestInterceptors {
  EsriRequestInterceptors(this._requestConfig);

  final JSObject _requestConfig;
  final _rules = RequestHeaderRules();
  List<JSObject> _created = const [];

  void set({
    required String urlPrefix,
    required int mapId,
    required RequestHeadersCallback headers,
  }) {
    _rules.set(urlPrefix: urlPrefix, mapId: mapId, headers: headers);
    _apply();
  }

  void clear(String urlPrefix) {
    _rules.clear(urlPrefix);
    _apply();
  }

  void clearMap(int mapId) {
    _rules.clearMap(mapId);
    _apply();
  }

  /// ArcGIS reads the array at each request, so assigning a new one is
  /// enough.
  void _apply() {
    final current = _requestConfig['interceptors'] as JSArray<JSObject>?;
    final others = [
      for (final interceptor in current?.toDart ?? const <JSObject>[])
        if (!_created.any((own) => own.strictEquals(interceptor).toDart))
          interceptor,
    ];
    _created = [
      for (final rule in _rules.rules)
        JsRequestInterceptor(urls: rule.urlPrefix.toJS, before: _before(rule)),
    ];
    _requestConfig['interceptors'] = [..._created, ...others].toJS;
  }

  static JSFunction _before(RequestHeaderRule rule) {
    return ((JsInterceptorParams params) => _withHeaders(rule, params)).toJS;
  }

  /// Fails the request when [RequestHeaderRule.headers] fails, rather than
  /// sending it without them. The rejection is a JS `Error` with the Dart
  /// error as its message, so the failed request reports the cause.
  static JSPromise<JSAny?> _withHeaders(
    RequestHeaderRule rule,
    JsInterceptorParams params,
  ) {
    return JSPromise<JSAny?>(
      (JSFunction resolve, JSFunction reject) {
        _addHeaders(rule, params).then(
          (_) => resolve.callAsFunction(),
          onError: (Object e, StackTrace stack) {
            developer.log(
              'Error adding request headers for ${rule.urlPrefix}',
              name: 'arcgis_map_sdk_web',
              error: e,
              stackTrace: stack,
              level: 1000,
            );
            return reject.callAsFunction(null, JsError('$e'));
          },
        );
      }.toJS,
    );
  }

  static Future<void> _addHeaders(
    RequestHeaderRule rule,
    JsInterceptorParams params,
  ) async {
    final headers = await rule.headers();
    final options = params.requestOptions;
    final own = options.headers.dartify() as Map<Object?, Object?>?;
    options.headers = {...?own, ...headers}.jsify()! as JSObject;
  }
}
