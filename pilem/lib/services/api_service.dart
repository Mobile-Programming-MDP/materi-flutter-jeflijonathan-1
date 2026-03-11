import 'dart:convert';
import 'package:http/http.dart' as http;

class APIService {
  static const String apiKey = '665ad89fcbde8e53916279e50a90f65f';
  static const String baseUrl = 'https://api.themoviedb.org/3';
  //https://api.themoviedb.org/3/search/movie?query=""&api_key="665ad89fcbde8e53916279e50a90f65f"
  static String getImageUrl(String path) =>
      'https://image.tmdb.org/t/p/w500$path';

  // 1. mengambil list movie
  Future<List<Map<String, dynamic>>> getALLMovies() async {
    final url = Uri.parse('$baseUrl/movie/now_playing?api_key=$apiKey');

    final response = await http.get(url);
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data["results"]);
  }

  // 2. mengambil list tranding movie
  Future<List<Map<String, dynamic>>> getTrandingMovie() async {
    final url = Uri.parse('$baseUrl/trending/movie/week?api_key=$apiKey');

    final response = await http.get(url);
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data["results"]);
  }

  // 3. mengambil list popular movie
  Future<List<Map<String, dynamic>>> getPopularMoview() async {
    final url = Uri.parse('$baseUrl/movie/popular?api_key=$apiKey');

    final response = await http.get(url);
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data["results"]);
  }

  // 4. mengambil list movie mlalui pencarian
  Future<List<Map<String, dynamic>>> searchMovie(String query) async {
    String target = '$baseUrl/search/movie?query=$query&api_key=$apiKey';

    if (query == "" || query.isEmpty) {
      target = '$baseUrl/movie/now_playing?api_key=$apiKey';
    }

    final url = Uri.parse(target);

    final response = await http.get(url);
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data["results"]);
  }
}
