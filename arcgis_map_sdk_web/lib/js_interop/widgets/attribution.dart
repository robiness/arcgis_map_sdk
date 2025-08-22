/// ArcGIS Maps SDK for JavaScript - Attribution widget
/// 
/// Contains the Attribution widget for displaying map attribution text.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-widgets-Attribution.html
import 'dart:js_interop';

/// Attribution widget for displaying map attribution text
@JS("esri.widgets.Attribution")
extension type JsAttribution._(JSObject _) implements JSObject {
  external factory JsAttribution(JSObject properties);
  
  /// Whether the widget is visible
  external bool get visible;
  external set visible(bool value);
  
  /// The attribution text content
  external String get attributionText;
  
  /// The view associated with the widget
  external JSObject? get view;
  external set view(JSObject? value);
  
  /// Container for the widget
  external JSObject? get container;
  external set container(JSObject? value);
  
  /// Destroy the widget
  external void destroy();
}
