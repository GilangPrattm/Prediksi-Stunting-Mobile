import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'chatbot_history_page.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, String>> _messagesUI = [];
  final List<Map<String, dynamic>> _historyGemini = [];
  bool _isLoading = false;

  final String _sessionId = DateTime.now().toIso8601String(); // Tag id percakapan unik ini

  @override
  void initState() {
    super.initState();
    // Otak sistem sekarang semuanya tersimpan rapat dengan aman di Server Laravel!
    _messagesUI.add({
      'sender': 'ai',
      'text': 'Halo Bunda! Mesin Kila sekarang makin canggih dan ramah. Mari berdiskusi!'
    });
    _saveToLocalStorage(); // Simpan pesan pertama ke memori HP
  }

  void _saveToLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? existing = prefs.getString('chat_sessions');
    List<dynamic> sessions = existing != null ? jsonDecode(existing) : [];
    
    // Cari sesi ini apakah sudah terekam di memori, jika ya timpa, jika tiada buat baru
    int curIdx = sessions.indexWhere((s) => s['id'] == _sessionId);
    if (curIdx >= 0) {
      sessions[curIdx]['messages'] = _messagesUI;
    } else {
      sessions.add({
        'id': _sessionId,
        'date': _sessionId, 
        'messages': _messagesUI
      });
    }
    
    await prefs.setString('chat_sessions', jsonEncode(sessions));
  }

  void _kirimPesan() async {
    if (_msgController.text.trim().isEmpty) return;
    
    String userText = _msgController.text.trim();
    
    setState(() {
      _messagesUI.insert(0, {'sender': 'user', 'text': userText});
      _isLoading = true;
      _msgController.clear();
    });
    
    _saveToLocalStorage(); // Rekam history setiap user ngomong

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': userText,
          'history': _historyGemini
        }),
      );

      // Simpan histori chat milik User untuk siklus berikutnya
      _historyGemini.add({
        'role': 'user', 
        'parts': [{'text': userText}]
      });

      if (response.statusCode == 200) {
        final dataJson = jsonDecode(response.body);
        String balas = dataJson['reply'] ?? 'Terjadi kebisuan Server AI';
        
        setState(() {
          _messagesUI.insert(0, {'sender': 'ai', 'text': balas});
        });
        
        // Simpan balik memori dari jawaban AI
        _historyGemini.add({
          'role': 'model', 
          'parts': [{'text': balas}]
        });
        
        _saveToLocalStorage(); // Simpan riwayat update jawaban AI ke HP

      } else {
        setState(() {
          _messagesUI.insert(0, {'sender': 'ai', 'text': 'Waduh, Server Backend menolak pesan. Detail: ${response.statusCode}'});
        });
      }
    } catch (e) {
      setState(() {
        _messagesUI.insert(0, {'sender': 'ai', 'text': 'Koneksi ke server pusat Laravel terputus. Nyalakan server lalu coba lagi.'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFBFDBFE); // Light Blue color

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(radius: 16, backgroundColor: Colors.white, child: Icon(Icons.smart_toy, color: Color(0xFF1E293B), size: 18)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kila AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text('• Online', style: TextStyle(fontSize: 11, color: Color(0xFF1E293B).withOpacity(0.7))),
              ],
            ),
          ],
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Obrolan',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotHistoryPage()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Area Percakapan
          Expanded(
            child: ListView.builder(
              reverse: true, // Membalik urutan agar pesan baru ada di bawah but view-nya ngikut
              padding: const EdgeInsets.all(16),
              itemCount: _messagesUI.length,
              itemBuilder: (context, index) {
                bool isUser = _messagesUI[index]['sender'] == 'user';
                return _buildPesanBubble(isUser, _messagesUI[index]['text']!, primaryColor);
              },
            ),
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
                    const SizedBox(width: 10),
                    Text('Mengetik...', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),

          // Suggestion Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _buildSuggestionPill('Apa MPASI yang bagus untuk usia 8 bulan?'),
                _buildSuggestionPill('Berapa berat ideal anak 1 tahun?'),
                _buildSuggestionPill('Cara menaikkan berat badan balita'),
              ],
            ),
          ),

          // Area Keyboard Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Row(
              children: [
                const Icon(Icons.mood, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Tanya Kila...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (value) => _kirimPesan(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _kirimPesan,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Color(0xFF1E293B), size: 20),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSuggestionPill(String text) {
    return GestureDetector(
      onTap: () {
        _msgController.text = text;
        _kirimPesan();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFF1E293B).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPesanBubble(bool isUser, String isian, Color primaryColor) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) // Icon Bot
          Container(
            margin: const EdgeInsets.only(right: 8, bottom: 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy, color: Color(0xFF1E293B), size: 16),
          ),
        
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
          decoration: BoxDecoration(
            color: isUser ? primaryColor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
              bottomRight: isUser ? Radius.zero : const Radius.circular(20),
            ),
            border: Border.all(color: isUser ? primaryColor : Colors.grey.shade200),
            boxShadow: [if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.all(15),
          child: isUser 
            ? Text(isian, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14))
            : MarkdownBody(
                data: isian,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14, color: Colors.black87),
                  strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
        ),
      ],
    );
  }
}
