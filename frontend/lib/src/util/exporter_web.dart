import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web: trigger a real browser download of the export JSON. Returns 'download'.
Future<String> saveExport(String filename, String contents) async {
  final blob = web.Blob(
    [contents.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return 'download';
}
