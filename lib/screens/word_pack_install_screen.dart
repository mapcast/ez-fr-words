import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';

class WordPackInstallScreen extends StatefulWidget {
  const WordPackInstallScreen({super.key});

  @override
  State<WordPackInstallScreen> createState() => _WordPackInstallScreenState();
}

class _WordPackInstallScreenState extends State<WordPackInstallScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isInstalling = false;
  String? _selectedPack;
  int? _importedCount;
  bool _isLoading = true;
  bool _isInstallingAll = false;
  Map<String, bool> _installedPacks = {};
  Map<String, int> _packWordCounts = {};

  final List<Map<String, String>> _availablePacks = List.generate(
    26,
    (index) {
      final letter = String.fromCharCode(65 + index).toLowerCase(); // A-Z를 a-z로 변환
      final upperLetter = String.fromCharCode(65 + index); // A-Z
      
      return {
        'name': '프랑스어 단어장 $upperLetter',
        'file': 'france_dictionary_$letter.json',
        'description': '$upperLetter로 시작하는 프랑스어 단어 모음',
        'prefix': letter,
      };
    },
  );

  @override
  void initState() {
    super.initState();
    _checkInstalledPacks();
  }

  Future<void> _checkInstalledPacks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (var pack in _availablePacks) {
        final prefix = pack['prefix']!;
        final isInstalled = await _databaseHelper.isWordPackInstalled(prefix);
        final wordCount = await _databaseHelper.getWordPackCount(prefix);
        
        setState(() {
          _installedPacks[pack['file']!] = isInstalled;
          _packWordCounts[pack['file']!] = wordCount;
        });
      }
    } catch (e) {
      // 오류 무시 (데이터베이스가 비어있을 수 있음)
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _installWordPack(String fileName) async {
    setState(() {
      _isInstalling = true;
      _selectedPack = fileName;
    });

    try {
      // JSON 파일 읽기
      final String jsonString = await rootBundle.loadString('assets/$fileName');
      
      // 데이터베이스에 import
      final int count = await _databaseHelper.importFromJson(jsonString);
      
      setState(() {
        _importedCount = count;
        _isInstalling = false;
        _installedPacks[fileName] = true;
        _packWordCounts[fileName] = count;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count개의 단어가 성공적으로 추가되었습니다!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // 잠시 후 메인 화면으로 돌아가기
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isInstalling = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어 팩 설치 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteWordPack(String fileName, String packName) async {
    // 삭제 확인 다이얼로그
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('단어 팩 삭제'),
          content: Text('$packName을(를) 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isInstalling = true;
      _selectedPack = fileName;
    });

    try {
      // 해당 단어 팩의 접두사 찾기
      final pack = _availablePacks.firstWhere((p) => p['file'] == fileName);
      final prefix = pack['prefix']!;
      
      // 데이터베이스에서 삭제
      final int deletedCount = await _databaseHelper.deleteWordPack(prefix);
      
      setState(() {
        _isInstalling = false;
        _installedPacks[fileName] = false;
        _packWordCounts[fileName] = 0;
        _importedCount = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount개의 단어가 삭제되었습니다.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isInstalling = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어 팩 삭제 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _installAllWordPacks() async {
    // 설치할 단어장 목록 확인
    final uninstalledPacks = _availablePacks.where((pack) => 
      !(_installedPacks[pack['file']!] ?? false)
    ).toList();

    if (uninstalledPacks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('설치할 단어장이 없습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 확인 다이얼로그
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('모든 단어장 설치'),
          content: Text(
            '설치되지 않은 ${uninstalledPacks.length}개의 단어장을 모두 설치하시겠습니까?\n\n'
            '이 작업은 시간이 걸릴 수 있습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B46C1)),
              child: const Text('설치'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isInstallingAll = true;
    });

    int totalImported = 0;

    try {
      for (var pack in uninstalledPacks) {
        final fileName = pack['file']!;
        
        // JSON 파일 읽기
        final String jsonString = await rootBundle.loadString('assets/$fileName');
        
        // 데이터베이스에 import
        final int count = await _databaseHelper.importFromJson(jsonString);
        totalImported += count;
        
        // 상태 업데이트
        setState(() {
          _installedPacks[fileName] = true;
          _packWordCounts[fileName] = count;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('총 $totalImported개의 단어가 성공적으로 추가되었습니다!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // 잠시 후 메인 화면으로 돌아가기
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단어장 설치 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isInstallingAll = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 팩 설치'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 헤더 섹션
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6B46C1).withOpacity(0.05),
                        const Color(0xFF6B46C1).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B46C1).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download,
                          size: 48,
                          color: Color(0xFF6B46C1),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '단어 팩을 선택하여 설치하세요',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B46C1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '설치된 단어는 단어장에서 확인할 수 있습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // 추가: 전체 설치 버튼
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _isInstallingAll || _isInstalling 
                        ? null 
                        : _installAllWordPacks,
                    icon: _isInstallingAll
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download_for_offline),
                    label: Text(
                      _isInstallingAll 
                          ? '설치 중...' 
                          : '모든 단어장 설치',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B46C1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                
                // 단어 팩 목록
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _availablePacks.length,
                    itemBuilder: (context, index) {
                      final pack = _availablePacks[index];
                      final fileName = pack['file']!;
                      final isInstalled = _installedPacks[fileName] ?? false;
                      final isSelected = _selectedPack == fileName;
                      final isInstalling = _isInstalling && isSelected;
                      final wordCount = _packWordCounts[fileName] ?? 0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pack['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              if (isInstalled)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '설치됨',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                pack['description']!,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 15,
                                ),
                              ),
                              if (isInstalled && wordCount > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '설치된 단어: $wordCount개',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              if (isSelected && _importedCount != null && !isInstalled) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '설치 완료: $_importedCount개 단어',
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: isInstalling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isInstalled)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: isInstalling || _isInstallingAll
                                            ? null 
                                            : () => _deleteWordPack(fileName, pack['name']!),
                                        tooltip: '삭제',
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        isInstalled 
                                            ? Icons.check_circle 
                                            : Icons.download,
                                        color: isInstalled ? Colors.green : Colors.blue,
                                      ),
                                      onPressed: isInstalled || isInstalling || _isInstallingAll
                                          ? null 
                                          : () => _installWordPack(fileName),
                                      tooltip: isInstalled ? '설치됨' : '설치',
                                    ),
                                  ],
                                ),
                          onTap: isInstalled || isInstalling || _isInstallingAll
                              ? null 
                              : () => _installWordPack(fileName),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
} 