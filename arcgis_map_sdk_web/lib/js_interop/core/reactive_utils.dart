/// ArcGIS Maps SDK for JavaScript - reactiveUtils
///
/// Modern API for observing reactive property changes. Replaces the
/// deprecated `view.watch(prop, callback)` pattern (deprecated since 4.32).
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-core-reactiveUtils.html
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/core/handles.dart';

/// Reactive utilities loaded via `$arcgis.import("@arcgis/core/core/reactiveUtils.js")`
/// and stashed on `window.reactiveUtils` during bootstrap.
@JS('window.reactiveUtils')
external JsReactiveUtils get reactiveUtils;

extension type JsReactiveUtils._(JSObject _) implements JSObject {
  /// Watches the reactive expression evaluated by [getter] and invokes
  /// [callback] `(newValue, oldValue)` whenever the resolved value changes.
  ///
  /// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-core-reactiveUtils.html#watch
  external JsHandle watch(JSFunction getter, JSFunction callback);

  /// Resolves once [getValue] returns truthy. For "wait until view.ready"
  /// prefer this over `view.when()` — that one resolves immediately on a
  /// view that was once ready but is currently transitioning, so callbacks
  /// fire before the view is actually usable.
  ///
  /// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-core-reactiveUtils.html#whenOnce
  external JSPromise<JSAny?> whenOnce(JSFunction getValue);
}
