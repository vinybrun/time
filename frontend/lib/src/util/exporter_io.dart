import 'package:flutter/services.dart';

/// Non-web: put the export JSON on the clipboard. Returns 'clipboard'.
Future<String> saveExport(String filename, String contents) async {
  await Clipboard.setData(ClipboardData(text: contents));
  return 'clipboard';
}
