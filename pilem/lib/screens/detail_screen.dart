import 'package:flutter/material.dart';
import 'package:pilem/models/movie.dart';
import 'package:pilem/widget/is_empty_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailScreen extends StatefulWidget {
  final Movie movie;

  const DetailScreen({super.key, required this.movie});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _getFavoriteStatus();
  }

  Future<void> _getFavoriteStatus() async {
    final pref = await SharedPreferences.getInstance();
    final favoriteMovies = pref.getStringList('favoriteMovies') ?? [];

    setState(() {
      _isFavorite = favoriteMovies.contains(widget.movie.id.toString());
    });
  }

  Future<void> _toggleFavorite() async {
    final pref = await SharedPreferences.getInstance();
    final favoriteMovies = pref.getStringList('favoriteMovies') ?? [];

    if (_isFavorite) {
      favoriteMovies.remove(widget.movie.id.toString());
    } else {
      favoriteMovies.add(widget.movie.id.toString());
    }

    await pref.setStringList('favoriteMovies', favoriteMovies);

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

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
              const SizedBox(height: 2),
              IsEmptyImage(
                urlImage: widget.movie.posterPath,
                width: double.infinity,
                heigth: 400,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  IconButton(
                    hoverColor: Colors.transparent,
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.grey,
                      size: 30,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  Text(
                    _isFavorite ? "Added to Favorites" : "Add to Favorites",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "Overview",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  widget.movie.overview,
                  textAlign: TextAlign.justify,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Text(
                    "Release Date: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 5),
                  Text(widget.movie.releaseDate),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.star, color: Colors.yellow),
                  const SizedBox(width: 10),
                  const Text(
                    "Rating: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 5),
                  Text('${widget.movie.voteAverage}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
