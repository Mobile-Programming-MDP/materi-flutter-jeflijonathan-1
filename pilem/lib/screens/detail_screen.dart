import 'package:flutter/material.dart';
import 'package:pilem/models/movie.dart';
import 'package:pilem/widget/is_empty_image.dart';

class DetailScreen extends StatefulWidget {
  final Movie movie;

  const DetailScreen({super.key, required this.movie});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.movie.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              IsEmptyImage(
                urlImage: widget.movie.posterPath,
                width: double.infinity,
                heigth: 400,
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                },
                child: Text(
                  _isFavorite ? "Remove from Favorites" : "Add to Favorites",
                ),
              ),

              SizedBox(height: 8),
              Text(
                "Overview",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(widget.movie.overview),
              // Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
