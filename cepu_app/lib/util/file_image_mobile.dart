import 'dart:io';
import 'package:flutter/widgets.dart';

Widget buildFileImage(String path) {
  return Image.file(
    File(path),
    fit: BoxFit.cover,
    width: double.infinity,
    height: 280,
    errorBuilder: (context, error, stackTrace) => Container(
      height: 280,
      color: const Color(0xFFEEEEEE),
      child: const Icon(IconData(0xe115, fontFamily: 'MaterialIcons'), size: 64, color: Color(0xFF9E9E9E)),
    ),
  );
}
