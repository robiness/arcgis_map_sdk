import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/src/arcgis_map_web_controller.dart';

@JS('esri/Graphic')
class JsGraphic {
  external JsGraphic(JSObject properties);

  external JSObject get symbol;
  external set symbol(JSObject symbol);
}
