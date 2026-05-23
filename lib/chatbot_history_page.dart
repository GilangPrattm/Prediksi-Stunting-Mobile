import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'chatbot_page.dart';

class ChatbotHistoryPage extends StatefulWidget {
  const ChatbotHistoryPage({super.key});

  @override
  State<ChatbotHistoryPage> createState() => _ChatbotHistoryPageState();
}

class _ChatbotHistoryPageState extends State<ChatbotHistoryPage> {
  List<dynamic> _historyList = [];

  // Tema Warna yang sesuai dengan ChatbotPage (Teal/Medical Light Blue)
  final Color _primary = const Color(0xFF006A63);
  final Color _primaryFixed = const Color(0xFF8EF4E9);
  final Color _surfaceLowest = const Color(0xFFFFFFFF);
  final Color _surfaceHigh = const Color(0xFFE6E8E8);
  final Color _onSurface = const Color(0xFF191C1D);
  final Color _onSurfaceVariant = const Color(0xFF3D4947);
  final Color _bgStart = const Color(0xFFF8FAFA);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString('chat_sessions');
    if (jsonStr != null) {
      setState(() {
        _historyList = jsonDecode(jsonStr);
        // Urutkan dari yang terbaru
        _historyList.sort((a, b) => b['date'].compareTo(a['date']));
      });
    }
  }

  void _clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_sessions');
    setState(() {
      _historyList.clear();
    });
  }

  void _deleteSession(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _historyList.removeAt(index);
    });
    await prefs.setString('chat_sessions', jsonEncode(_historyList));
  }

  void _continueSession(Map<String, dynamic> session) {
    List rawMsgs = session['messages'] ?? [];
    List<Map<String, String>> messages = rawMsgs.map<Map<String, String>>((m) {
      return {
        'sender': m['sender']?.toString() ?? 'ai',
        'text': m['text']?.toString() ?? '',
      };
    }).toList();

    // Memuat ulang sesi di Halaman Utama Chatbot, BUKAN menumpuk halaman baru.
    // Ini adalah pola standar seperti ChatGPT / Gemini.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotPage(
          sessionId: session['id'],
          initialMessages: messages,
        ),
      ),
      (Route<dynamic> route) => route.isFirst, // Kembali ke Root (misal Home), lalu tumpuk Chat baru
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgStart,
      appBar: AppBar(
        title: Text(
          'Riwayat Percakapan',
          style: TextStyle(
            color: _onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _surfaceLowest,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _surfaceHigh, height: 1.0),
        ),
        iconTheme: IconThemeData(color: _onSurfaceVariant),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep, color: _onSurfaceVariant),
            tooltip: 'Hapus Semua',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Semua Riwayat?'),
                  content: const Text(
                    'Seluruh sesi obrolan Anda dengan Kila akan dihapus permanen dari memori HP.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal', style: TextStyle(color: _onSurfaceVariant)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearHistory();
                      },
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _historyList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: _surfaceHigh),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat obrolan.',
                    style: TextStyle(color: _onSurfaceVariant, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _historyList.length,
                    itemBuilder: (context, index) {
                      var session = _historyList[index];
                      List msgs = session['messages'] ?? [];

                      // Cari pesan pembuka pengguna
                      String firstMessage = 'Percakapan dengan Kila';
                      if (msgs.isNotEmpty) {
                        var userMsgs = msgs.where((m) => m['sender'] == 'user').toList();
                        if (userMsgs.isNotEmpty) {
                          firstMessage = userMsgs.last['text']; 
                        } else {
                          firstMessage = msgs.first['text'];
                        }
                      }

                      return Dismissible(
                        key: Key(session['id'] ?? index.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Hapus Sesi Ini?'),
                              content: const Text('Percakapan ini akan dihapus dari riwayat.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal', style: TextStyle(color: _onSurfaceVariant))),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => _deleteSession(index),
                        child: GestureDetector(
                          onTap: () => _continueSession(session),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _surfaceLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _surfaceHigh),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _primaryFixed.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.forum_outlined, color: _primary, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        firstMessage,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _onSurface),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        session['date'].toString().split('.').first.replaceAll('T', ' \u2022 '),
                                        style: TextStyle(color: _onSurfaceVariant, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 12),
                  child: Text(
                    'Riwayat percakapan disimpan secara lokal di perangkat Anda.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}