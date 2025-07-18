class Word {
  final int? id;
  final String word;
  final String read;
  final String katakana;
  final String meaning;
  final String country;

  Word({
    this.id,
    required this.word,
    required this.read,
    required this.katakana,
    required this.meaning,
    this.country = 'france',
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      word: json['word'] ?? '',
      read: json['read'] ?? '',
      katakana: json['katakana'] ?? '',
      meaning: json['meaning'] ?? '',
      country: json['country'] ?? 'france',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'read': read,
      'katakana': katakana,
      'meaning': meaning,
      'country': country,
    };
  }
} 