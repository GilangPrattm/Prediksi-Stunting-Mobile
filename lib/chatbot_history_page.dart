import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Obrolan Kila', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Hapus Semua',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hapus Semua Riwayat?'),
                  content: const Text('Seluruh sesi obrolan Anda dengan Kila akan dihapus permanen dari memori HP.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearHistory();
                      },
                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: _historyList.isEmpty
          ? const Center(child: Text('Belum ada riwayat obrolan.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _historyList.length,
              itemBuilder: (context, index) {
                var session = _historyList[index];
                List msgs = session['messages'] ?? [];
                
                // Cari pesan pembuka atau terakhir pengguna
                String lastPreview = 'Tidak ada pesan';
                if (msgs.isNotEmpty) {
                    // Karena array disortir terbalik (reverse), pesan terbaru ada di index 0
                    lastPreview = msgs.first['text']; 
                }

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Icon(Icons.history, color: Colors.white),
                    ),
                    title: Text(
                      'Sesi ${session['date'].toString().split('.').first.replaceAll('T', ' ')}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                    subtitle: Text(
                      lastPreview.length > 50 ? '${lastPreview.substring(0, 50)}...' : lastPreview,
                      maxLines: 2,
                    ),
                    onTap: () {
                      _showDetail(context, msgs);
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showDetail(BuildContext context, List msgs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 5, width: 50,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const Padding(
                padding: EdgeInsets.all(15.0),
                child: Text('Kilas Balik Percakapan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Expanded(
                child: ListView.builder(
                  reverse: true, // Mengikuti chatbot yang disusun dari paling bawah
                  padding: const EdgeInsets.all(15),
                  itemCount: msgs.length,
                  itemBuilder: (context, idx) {
                    bool isUser = msgs[idx]['sender'] == 'user';
                    String text = msgs[idx]['text'];
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue[50] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: MarkdownBody(data: text),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
