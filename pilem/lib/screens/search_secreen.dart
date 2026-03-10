import 'package:flutter/material.dart';
import 'dart:async';

import 'package:pilem/models/movie.dart';
import 'package:pilem/services/api_service.dart';
import 'package:pilem/widget/is_empty_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Movie> _searchMovies = [];
  final _apiService = APIService();
  Timer? _debounce;

  Future<void> _fetchSearchMovies(String value) async {
    final List<Map<String, dynamic>> searchMovies = await _apiService
        .searchMovie(value);

    setState(() {
      _searchMovies = searchMovies
          .map((movie) => Movie.fromJson(movie))
          .toList();
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSearchMovies(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Movies")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: "Search movies...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(child: _buildMovieList(_searchMovies)),
        ],
      ),
    );
  }

  Widget _buildMovieList(List<Movie> movies) {
    if (movies.isEmpty) {
      return const Center(child: Text("No movies found"));
    }

    return ListView.builder(
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return Card(
          elevation: 5,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            leading: IsEmptyImage(urlImage: movie.posterPath),
            title: Text(movie.title),
            subtitle: Text(movie.overview),
          ),
        );
      },
    );
  }
}
