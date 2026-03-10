import 'package:flutter/material.dart';
import 'package:pilem/services/api_service.dart';

class IsEmptyImage extends StatefulWidget {
  final String urlImage;

  const IsEmptyImage({super.key, required this.urlImage});

  @override
  State<IsEmptyImage> createState() => _IsEmptyImageState();
}

class _IsEmptyImageState extends State<IsEmptyImage> {
  @override
  Widget build(BuildContext context) {
    if (widget.urlImage.isEmpty) {
      return Container(
        width: 100,
        height: 150,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 50, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        APIService.getImageUrl(widget.urlImage),
        width: 100,
        height: 150,
        fit: BoxFit.cover,
      ),
    );
  }
}
