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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotPage(
          sessionId: session['id'],
          initialMessages: messages,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFBFDBFE); // Light Blue color

    return Scaffold(
      backgroundColor: Colors.white, // White background matching design
      appBar: AppBar(
        title: const Text(
          'Riwayat Percakapan',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
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
                      child: const Text('Batal'),
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
          ? const Center(
              child: Text(
                'Belum ada riwayat obrolan.',
                style: TextStyle(color: Colors.grey),
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

                      // Cari pesan pembuka atau terakhir pengguna
                      String firstMessage = 'Tidak ada pesan';
                      if (msgs.isNotEmpty) {
                        // Karena array disortir terbalik (reverse), pesan terbaru ada di index 0
                        // Namun untuk preview judul yang masuk akal, kita ambil pesan awal dari sesi (yang terakhir di array reverse)
                        var userMsgs = msgs
                            .where((m) => m['sender'] == 'user')
                            .toList();
                        if (userMsgs.isNotEmpty) {
                          firstMessage = userMsgs
                              .last['text']; // Last in reversed list = First actual message
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
                            borderRadius: BorderRadius.circular(15),
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
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => _deleteSession(index),
                        child: GestureDetector(
                          onTap: () => _continueSession(session),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))]
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFa7f3d0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline, color: primaryColor, size: 24),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        firstMessage.length > 35 ? '${firstMessage.substring(0, 35)}...' : firstMessage,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        session['date'].toString().split('.').first.replaceAll('T', ' \u2022 '),
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Lanjutkan', style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios, color: primaryColor, size: 10),
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
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Text(
                    'Riwayat percakapan disimpan selama 30 hari terakhir',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.indigo.shade200,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

}
