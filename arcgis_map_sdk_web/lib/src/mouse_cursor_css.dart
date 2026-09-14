import 'package:flutter/services.dart';

/// CSS `cursor` values per [SystemMouseCursor.kind], mirroring the mapping
/// Flutter web uses for its own canvas so the map shows the same cursor a
/// Flutter widget would.
const Map<String, String> _cssCursorByKind = {
  'alias': 'alias',
  'allScroll': 'move',
  'basic': 'default',
  'cell': 'cell',
  'click': 'pointer',
  'contextMenu': 'context-menu',
  'copy': 'copy',
  'forbidden': 'not-allowed',
  'grab': 'grab',
  'grabbing': 'grabbing',
  'help': 'help',
  'move': 'move',
  'none': 'none',
  'noDrop': 'no-drop',
  'precise': 'crosshair',
  'progress': 'progress',
  'text': 'text',
  'resizeColumn': 'col-resize',
  'resizeDown': 's-resize',
  'resizeDownLeft': 'sw-resize',
  'resizeDownRight': 'se-resize',
  'resizeLeft': 'w-resize',
  'resizeLeftRight': 'ew-resize',
  'resizeRight': 'e-resize',
  'resizeRow': 'row-resize',
  'resizeUp': 'n-resize',
  'resizeUpDown': 'ns-resize',
  'resizeUpLeft': 'nw-resize',
  'resizeUpRight': 'ne-resize',
  'resizeUpLeftDownRight': 'nwse-resize',
  'resizeUpRightDownLeft': 'nesw-resize',
  'verticalText': 'vertical-text',
  'wait': 'wait',
  'zoomIn': 'zoom-in',
  'zoomOut': 'zoom-out',
};

/// The CSS `cursor` value for [cursor]; unknown kinds fall back to `default`.
String cssCursorFor(SystemMouseCursor cursor) => _cssCursorByKind[cursor.kind] ?? 'default';
