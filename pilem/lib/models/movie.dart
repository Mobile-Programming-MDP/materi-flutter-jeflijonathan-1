class Movie {
  final bool adult;
  final String backdropPath;
  final List<int> genreIds;
  final int id;
  final String originalLanguage;
  final String originalTitle;
  final String overview;
  final double popularity;
  final String posterPath;
  final String releaseDate;
  final String title;
  final bool video;
  final double voteAverage;
  final int voteCount;

  Movie({
    required this.adult,
    required this.backdropPath,
    required this.genreIds,
    required this.id,
    required this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.releaseDate,
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json["id"] ?? "",
      title: json["title"] ?? "",
      overview: json["overview"] ?? "",
      posterPath: json["backdrop_path"] ?? "",
      backdropPath: json["backdrop_path"] ?? "",
      releaseDate: json["release_date"] ?? "",
      voteAverage: json["vote_average"].toDouble() ?? "",
      voteCount: json["vote_count"] ?? "",
      video: json["video"] ?? false,
      popularity: json["popularity"].toDouble() ?? "",
      originalLanguage: json["original_language"] ?? "",
      originalTitle: json["original_title"] ?? "",
      adult: json["adult"] ?? false,
      genreIds: List<int>.from(json["genre_ids"] ?? []),
    );
  }
}
