import 'package:flutter/material.dart';
import '../models/word.dart';
import '../utils/tts_helper.dart';

class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({super.key});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final TTSHelper _ttsHelper = TTSHelper();
  bool _isSpeaking = false;

  @override
  void dispose() {
    _ttsHelper.stop();
    super.dispose();
  }

  Future<void> _speakWord(String word) async {
    setState(() {
      _isSpeaking = true;
    });

    try {
      await _ttsHelper.speakFrench(word);
    } finally {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 전달받은 단어 데이터 가져오기
    final Word word = ModalRoute.of(context)!.settings.arguments as Word;

    return Scaffold(
      appBar: AppBar(
        title: Text(word.word),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 단어 카드
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6B46C1).withOpacity(0.05),
                      const Color(0xFF6B46C1).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // 단어
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          word.country == 'france'
                              ? 'icons/flags/png/fr.png'
                              : word.country == 'germany'
                                  ? 'icons/flags/png/de.png'
                                  : word.country == 'italy'
                                      ? 'icons/flags/png/it.png'
                                      : 'icons/flags/png/fr.png', // 기본값: 프랑스
                          package: 'country_icons',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          word.word,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B46C1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            _isSpeaking ? Icons.volume_off : Icons.volume_up,
                            color: _isSpeaking ? const Color(0xFFEF4444) : const Color(0xFF6B46C1),
                            size: 32,
                          ),
                          onPressed: _isSpeaking 
                              ? () => _ttsHelper.stop()
                              : () => _speakWord(word.word),
                          tooltip: _isSpeaking ? '발음 중지' : '프랑스어 발음 듣기',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 발음
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B46C1).withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        word.read,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // 카타카나 섹션
            _buildInfoSection(
              title: '카타카나',
              content: word.katakana,
              icon: Icons.language,
              color: const Color(0xFF10B981),
            ),
            
            const SizedBox(height: 20),
            
            // 뜻 섹션
            _buildInfoSection(
              title: '의미',
              content: word.meaning,
              icon: Icons.translate,
              color: const Color(0xFFF59E0B),
            ),
            
            const SizedBox(height: 32),
            
            // 추가 정보 카드
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline, 
                          color: Color(0xFF6B46C1),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '단어 정보',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B46C1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow('단어 ID', '${word.id}'),
                    _buildInfoRow('단어 길이', '${word.word.length}글자'),
                    _buildInfoRow('첫 글자', word.word[0].toUpperCase()),
                    _buildInfoRow('마지막 글자', word.word[word.word.length - 1]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                fontSize: 18,
                height: 1.6,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
} 