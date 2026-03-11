import 'package:flutter/material.dart';
import 'package:pilem/models/movie.dart';
import 'package:pilem/screens/detail_screen.dart';
import 'package:pilem/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart' as prefs;

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  APIService apiservice = APIService();
  List<Movie> favoriteMovieList = [];

  Future<void> fetchFavoriteMovieList() async {
    final res = await apiservice.getALLMovies();
    final pref = await prefs.SharedPreferences.getInstance();
    final listFavoriteMovie = pref.getStringList('favoriteMovies') ?? [];

    setState(() {
      favoriteMovieList = res
          .where(
            (movieData) =>
                listFavoriteMovie.contains(movieData["id"].toString()),
          )
          .map((movieData) => Movie.fromJson(movieData))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchFavoriteMovieList();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: favoriteMovieList.length,
      itemBuilder: (context, index) {
        final movie = favoriteMovieList[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(movie: movie)),
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    APIService.getImageUrl(movie.posterPath),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Judul Movie
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
