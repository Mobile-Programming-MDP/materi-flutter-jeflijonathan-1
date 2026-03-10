import 'package:flutter/material.dart';
import 'package:pilem/models/movie.dart';
import 'package:pilem/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final APIService _apiService = APIService();

  List<Movie> _allMovies = [];
  List<Movie> _trendingMovies = [];
  List<Movie> _popularMovies = [];

  Future<void> _loadMovie() async {
    final List<Map<String, dynamic>> allMovies = await _apiService
        .getALLMovies();
    final List<Map<String, dynamic>> trendingMovies = await _apiService
        .getTrandingMovie();
    final List<Map<String, dynamic>> popularMovies = await _apiService
        .getPopularMoview();

    setState(() {
      _allMovies = allMovies.map((movie) => Movie.fromJson(movie)).toList();
      _trendingMovies = trendingMovies
          .map((movie) => Movie.fromJson(movie))
          .toList();
      _popularMovies = popularMovies
          .map((movie) => Movie.fromJson(movie))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMovieList("All Movies", _allMovies),
          _buildMovieList("Trending Movies", _trendingMovies),
          _buildMovieList("Popular Movies", _popularMovies),
        ],
      ),
    );
  }

  Widget _buildMovieList(String title, List<Movie> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 120,
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Image.network(
                      APIService.getImageUrl(movie.posterPath),
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 8),
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
