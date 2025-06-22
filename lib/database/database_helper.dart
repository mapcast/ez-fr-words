import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/word.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'french_dictionary.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        read TEXT NOT NULL,
        katakana TEXT NOT NULL,
        meaning TEXT NOT NULL,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // 단어 추가
  Future<int> insertWord(Word word) async {
    final db = await database;
    return await db.insert('words', {
      'word': word.word,
      'read': word.read,
      'katakana': word.katakana,
      'meaning': word.meaning,
    });
  }

  // 모든 단어 가져오기 (페이징)
  Future<List<Word>> getAllWords({int offset = 0, int limit = 20}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      limit: limit,
      offset: offset,
      orderBy: 'id ASC',
    );
    return List.generate(maps.length, (i) {
      return Word(
        id: maps[i]['id'],
        word: maps[i]['word'],
        read: maps[i]['read'],
        katakana: maps[i]['katakana'],
        meaning: maps[i]['meaning'],
      );
    });
  }

  // 전체 단어 개수 가져오기
  Future<int> getTotalWordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return result.first['count'] as int;
  }

  // 단어 검색 (다양한 필드로 검색)
  Future<List<Word>> searchWords(String query, String searchType, {int offset = 0, int limit = 20}) async {
    final db = await database;
    String whereClause;
    List<String> whereArgs;

    switch (searchType) {
      case 'word':
        whereClause = 'word LIKE ?';
        whereArgs = ['$query%'];
        break;
      case 'meaning':
        whereClause = 'meaning LIKE ?';
        whereArgs = ['%$query%'];
        break;
      case 'read':
        whereClause = 'read LIKE ?';
        whereArgs = ['$query%'];
        break;
      default:
        whereClause = 'word LIKE ? OR meaning LIKE ? OR read LIKE ?';
        whereArgs = ['$query%', '%$query%', '$query%'];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'words',
      where: whereClause,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'id ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Word(
        id: maps[i]['id'],
        word: maps[i]['word'],
        read: maps[i]['read'],
        katakana: maps[i]['katakana'],
        meaning: maps[i]['meaning'],
      );
    });
  }

  // 검색 결과 개수 가져오기
  Future<int> getSearchResultCount(String query, String searchType) async {
    final db = await database;
    String whereClause;
    List<String> whereArgs;

    switch (searchType) {
      case 'word':
        whereClause = 'word LIKE ?';
        whereArgs = ['$query%'];
        break;
      case 'meaning':
        whereClause = 'meaning LIKE ?';
        whereArgs = ['%$query%'];
        break;
      case 'read':
        whereClause = 'read LIKE ?';
        whereArgs = ['$query%'];
        break;
      default:
        whereClause = 'word LIKE ? OR meaning LIKE ? OR read LIKE ?';
        whereArgs = ['$query%', '%$query%', '$query%'];
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM words WHERE $whereClause',
      whereArgs,
    );
    return result.first['count'] as int;
  }

  // 단어 삭제
  Future<int> deleteWord(String word) async {
    final db = await database;
    return await db.delete(
      'words',
      where: 'word = ?',
      whereArgs: [word],
    );
  }

  // JSON 파일에서 데이터 import
  Future<int> importFromJson(String jsonString) async {
    final db = await database;
    final List<dynamic> jsonData = json.decode(jsonString);
    int importedCount = 0;

    await db.transaction((txn) async {
      for (var item in jsonData) {
        await txn.insert('words', {
          'word': item['word'],
          'read': item['read'],
          'katakana': item['katakana'],
          'meaning': item['meaning'],
        });
        importedCount++;
      }
    });

    return importedCount;
  }

  // 단어 팩 설치 완료 여부 확인
  Future<bool> isWordPackInstalled(String packPrefix) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'words',
      where: 'word LIKE ?',
      whereArgs: ['$packPrefix%'],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // 특정 단어 팩의 단어 개수 확인
  Future<int> getWordPackCount(String packPrefix) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM words WHERE word LIKE ?',
      ['$packPrefix%'],
    );
    return result.first['count'] as int;
  }

  // 특정 단어 팩 삭제
  Future<int> deleteWordPack(String packPrefix) async {
    final db = await database;
    return await db.delete(
      'words',
      where: 'word LIKE ?',
      whereArgs: ['$packPrefix%'],
    );
  }

  // 데이터베이스 닫기
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 