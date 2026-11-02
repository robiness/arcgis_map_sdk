/// ArcGIS Maps SDK for JavaScript - Request interceptors
///
/// The entries of `esriConfig.request.interceptors`, which `esri/request`
/// consults for every request it makes.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-config.html#RequestInterceptor
library;

import 'dart:js_interop';

/// An entry of `esriConfig.request.interceptors`. ArcGIS calls `before` of
/// the first entry whose `urls` matches a request, with a
/// [JsInterceptorParams], and awaits a promise it returns. A result other
/// than null becomes the response, and the request is not sent.
extension type JsRequestInterceptor._(JSObject _) implements JSObject {
  external factory JsRequestInterceptor({JSAny? urls, JSFunction? before});
}

/// The argument of an interceptor's `before`.
extension type JsInterceptorParams._(JSObject _) implements JSObject {
  external String get url;
  external JsRequestOptions get requestOptions;
}

/// The options of the request an interceptor runs for.
extension type JsRequestOptions._(JSObject _) implements JSObject {
  /// Header names to values.
  external JSObject? get headers;
  external set headers(JSObject? value);
}
