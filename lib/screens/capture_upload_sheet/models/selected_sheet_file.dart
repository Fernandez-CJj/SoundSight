import 'dart:typed_data';

class SelectedSheetFile {
  const SelectedSheetFile({
    required this.name,
    required this.bytes,
    this.path,
  });

  final String name;
  final Uint8List bytes;
  final String? path;

  int get size => bytes.length;

  String? get extension {
    final dotIndex = name.lastIndexOf('.');

    if (dotIndex <= 0 || dotIndex == name.length - 1) {
      return null;
    }

    return name.substring(dotIndex + 1);
  }
}
