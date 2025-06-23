import 'package:flutter/material.dart';
import '../models/word.dart';
import '../database/database_helper.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  List<Word> words = [];
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;
  bool _hasSearched = false;
  
  // 페이징 관련 변수
  int _currentPage = 0;
  int _totalCount = 0;
  static const int _pageSize = 20;
  bool _hasMoreData = true;
  
  // 검색 타입
  String _searchType = 'all'; // 'all', 'word', 'meaning', 'read'
  final List<Map<String, String>> _searchTypes = [
    {'value': 'all', 'label': '전체'},
    {'value': 'word', 'label': '단어'},
    {'value': 'meaning', 'label': '뜻'},
    {'value': 'read', 'label': '발음'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTotalCount();
  }

  Future<void> _loadTotalCount() async {
    try {
      final count = await _databaseHelper.getTotalWordCount();
      setState(() {
        _totalCount = count;
      });
    } catch (e) {
      // 오류 무시 (데이터베이스가 비어있을 수 있음)
    }
  }

  Future<void> _searchWords({bool resetPage = true}) async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        words = [];
        _hasSearched = false;
        _currentPage = 0;
        _hasMoreData = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      if (resetPage) {
        _currentPage = 0;
        words = [];
      }
    });

    try {
      final query = _searchController.text.trim();
      final searchResults = await _databaseHelper.searchWords(
        query,
        _searchType,
        offset: _currentPage * _pageSize,
        limit: _pageSize,
      );

      setState(() {
        if (resetPage) {
          words = searchResults;
        } else {
          words.addAll(searchResults);
        }
        _hasSearched = true;
        _isLoading = false;
        _hasMoreData = searchResults.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _loadMoreWords() async {
    if (_isLoading || !_hasMoreData || _searchController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _currentPage++;
    });

    await _searchWords(resetPage: false);
  }

  void _onSearchTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _searchType = newValue;
      });
      if (_searchController.text.trim().isNotEmpty) {
        _searchWords();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namemaker'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 검색 섹션
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF3F4F6),
                  const Color(0xFFE5E7EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              children: [
                // 검색 타입과 검색어를 한 줄로 배치
                Row(
                  children: [
                    // 검색 타입 드롭다운
                    Container(
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        value: _searchType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _searchTypes.map((type) {
                          return DropdownMenuItem(
                            value: type['value'],
                            child: Text(
                              type['label']!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: _onSearchTypeChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 검색어 입력 필드
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          if (value.trim().isEmpty) {
                            setState(() {
                              words = [];
                              _hasSearched = false;
                              _currentPage = 0;
                              _hasMoreData = true;
                            });
                          }
                        },
                        onSubmitted: (value) => _searchWords(),
                        decoration: const InputDecoration(
                          hintText: '검색어를 입력하세요...',
                          prefixIcon: Icon(Icons.search, color: Color(0xFF6B46C1)),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 검색 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _searchWords,
                    icon: const Icon(Icons.search),
                    label: const Text('검색'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF6B46C1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 단어 목록
          Expanded(
            child: _buildWordList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/install');
        },
        child: const Icon(Icons.download),
        tooltip: '단어 팩 설치',
      ),
    );
  }

  Widget _buildWordList() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search, 
              size: 80, 
              color: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 24),
            Text(
              '검색어를 입력하여 단어를 찾아보세요',
              style: TextStyle(
                fontSize: 18, 
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '단어 팩을 먼저 설치해주세요',
              style: TextStyle(
                fontSize: 14, 
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading && words.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
        ),
      );
    }

    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off, 
              size: 80, 
              color: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 24),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 18, 
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadMoreWords();
        }
        return true;
      },
      child: ListView.builder(
        itemCount: words.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == words.length) {
            return _buildLoadingIndicator();
          }
          
          final word = words[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6B46C1).withOpacity(0.1),
                child: Image.asset(
                  word.country == 'france'
                      ? 'icons/flags/png/fr.png'
                      : word.country == 'germany'
                          ? 'icons/flags/png/de.png'
                          : word.country == 'italy'
                              ? 'icons/flags/png/it.png'
                              : 'icons/flags/png/fr.png', // 기본값: 프랑스
                  package: 'country_icons',
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              title: Text(
                word.word,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2937),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        word.read,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (word.katakana.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${word.katakana})',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word.meaning,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios, 
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/detail',
                  arguments: word,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B46C1)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 