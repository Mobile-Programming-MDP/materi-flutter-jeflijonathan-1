import 'dart:convert';
import 'package:http/http.dart' as http;

class APIService {
  static const String apiKey = '665ad89fcbde8e53916279e50a90f65f';
  static const String baseUrl = 'https://api.themoviedb.org/3';

  static String getImageUrl(String path) =>
      'https://image.tmdb.org/t/p/w500$path';
  Future<List<dynamic>> getPopularMovies() async {
    const apiKey = '665ad89fcbde8e53916279e50a90f65f';
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/popular?api_key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return data['results'];
    } else {
      throw Exception('Failed to load movies');
    }
  }
}
