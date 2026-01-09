import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Video_qyiaar_page.dart';
import 'report_page.dart';
import 'qyiaar_figure_detail_page.dart';
import 'qyiaar_Inspiration_list_page.dart';

class QyiaarInspirationListFullPage extends StatefulWidget {
  const QyiaarInspirationListFullPage({super.key});

  @override
  State<QyiaarInspirationListFullPage> createState() => _QyiaarInspirationListFullPageState();
}

class _QyiaarInspirationListFullPageState extends State<QyiaarInspirationListFullPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _characters = [];
  List<Map<String, dynamic>> _filteredCharacters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCharacters();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _loadCharacters() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/qyiaar_figure.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      final allCharacters = jsonData.cast<Map<String, dynamic>>();
      final filtered = await _filterBlockedCharacters(allCharacters);
      
      setState(() {
        _characters = allCharacters;
        _filteredCharacters = filtered;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading characters: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _filterBlockedCharacters(
    List<Map<String, dynamic>> characters,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedList = prefs.getStringList('blocked_characters') ?? [];
    final mutedList = prefs.getStringList('muted_characters') ?? [];
    final allBlocked = {...blockedList, ...mutedList};

    return characters.where((character) {
      final nickname = character['QyiaarNickName'] as String? ?? '';
      return !allBlocked.contains(nickname);
    }).toList();
  }

  Future<void> _blockCharacter(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedList = prefs.getStringList('blocked_characters') ?? [];
    if (!blockedList.contains(nickname)) {
      blockedList.add(nickname);
      await prefs.setStringList('blocked_characters', blockedList);
    }
    await _refreshData();
  }

  Future<void> _muteCharacter(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final mutedList = prefs.getStringList('muted_characters') ?? [];
    if (!mutedList.contains(nickname)) {
      mutedList.add(nickname);
      await prefs.setStringList('muted_characters', mutedList);
    }
    await _refreshData();
  }

  Future<void> _refreshData() async {
    final filtered = await _filterBlockedCharacters(_characters);
    setState(() {
      _filteredCharacters = filtered;
    });
  }

  void _showActionSheet(BuildContext context, Map<String, dynamic> character) {
    final nickname = character['QyiaarNickName'] ?? 'Unknown';
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPage(character: character),
                ),
              );
            },
            child: const Text(
              'Report',
              style: TextStyle(color: Colors.red),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _blockCharacter(nickname);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _muteCharacter(nickname);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              'Mute',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          isDefaultAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appreciate Voice Acting'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: QyiaarInspirationListPage(
                filteredCharacters: _filteredCharacters,
                onShowActionSheet: _showActionSheet,
                onRefreshData: _refreshData,
              ),
            ),
    );
  }
}

