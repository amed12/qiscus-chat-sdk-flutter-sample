import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  void debugLog(dynamic arg, [dynamic error, StackTrace? stackTrace]) {
    // Logger not available in new implementation - using print instead
    if (error != null && stackTrace != null) {
      print('$arg - Error: $error\nStackTrace: $stackTrace');
    } else if (error != null) {
      print('$arg - Error: $error');
    } else {
      print(arg);
    }
  }

  void pop<T extends Object>([T? result]) {
    Navigator.pop(this, result);
  }

  Future<T?> push<T extends Object>(Widget widget) async {
    return Navigator.push<T>(
      this,
      MaterialPageRoute(
        builder: (context) => widget,
      ),
    );
  }

  Future<T?> pushReplacement<T extends Object, TO extends Object>(
    Widget widget,
  ) async {
    return Navigator.pushReplacement<T, TO>(
      this,
      MaterialPageRoute(builder: (context) => widget),
    );
  }
}

extension FilePickerX on FilePicker {
  Future<File?> getFile({FileType type = FileType.image}) async {
    var result = await pickFiles(type: type);
    if (result?.files.first != null) {
      return File(result!.files.first.path!);
    }
    return null;
  }
}

extension IterableX<T> on Iterable<T> {
  T? safeWhere(bool Function(T) test) {
    try {
      return firstWhere(test);
    } on StateError {
      return null;
    }
  }
}
