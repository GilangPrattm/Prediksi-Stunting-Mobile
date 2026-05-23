import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'chatbot_history_page.dart';

class ChatbotPage extends StatefulWidget {
  final String? sessionId;
  final List<Map<String, String>>? initialMessages;

  const ChatbotPage({super.key, this.sessionId, this.initialMessages});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Controller untuk auto-scroll
  final List<Map<String, String>> _messagesUI = [];
  final List<Map<String, dynamic>> _historyGemini = [];
  bool _isLoading = false;

  late final String _sessionId;

  // -- Tema Warna Biru Konsisten --
  final Color _bgStart = const Color(0xFFF8F9FF); 
  final Color _bgMid = const Color(0xFFF8F9FF); 
  final Color _bgEnd = const Color(0x331978E5); 
  
  final Color _primary = const Color(0xFF1978E5); // Biru Utama
  final Color _primaryContainer = const Color(0xFFDCE9FF); 
  final Color _primaryFixed = const Color(0xFFEFF4FF); 
  
  final Color _surfaceLowest = const Color(0xFFFFFFFF);
  final Color _surfaceHigh = const Color(0xFFE2E8F0);
  
  final Color _onSurface = const Color(0xFF0B1C30);
  final Color _onSurfaceVariant = const Color(0xFF717785);
  final Color _secondary = const Color(0xFF1978E5);

  final String _kilaAvatarPath = 'assets/images/kila_icon.png';

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId ?? DateTime.now().toIso8601String();

    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      _messagesUI.addAll(widget.initialMessages!);
      _rebuildGeminiHistory();
      _scrollToBottom();
    } else {
      // Menggunakan .add() agar pesan muncul dari atas
      _messagesUI.add({
        'sender': 'ai',
        'text': 'Halo Bunda! Mesin Kila sekarang makin canggih dan ramah. Mari berdiskusi!'
      });
      _saveToLocalStorage();
    }
  }

  // Fungsi untuk scroll otomatis ke bawah saat ada pesan baru
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _rebuildGeminiHistory() {
    _historyGemini.clear();
    List<Map<String, dynamic>> tempHistory = [];
    String expectRole = 'user';
    
    // Looping maju karena array sekarang dari atas ke bawah
    for (int i = 0; i < _messagesUI.length; i++) {
      final msg = _messagesUI[i];
      if (msg['sender'] == 'user' && expectRole == 'user') {
        tempHistory.add({'role': 'user', 'parts': [{'text': msg['text']}]});
        expectRole = 'model';
      } else if (msg['sender'] == 'ai' && expectRole == 'model') {
        tempHistory.add({'role': 'model', 'parts': [{'text': msg['text']}]});
        expectRole = 'user';
      } else if (msg['sender'] == 'error') {
        if (expectRole == 'model' && tempHistory.isNotEmpty) {
           tempHistory.removeLast(); 
           expectRole = 'user';
        }
      }
    }
    if (expectRole == 'model' && tempHistory.isNotEmpty) tempHistory.removeLast();
    _historyGemini.addAll(tempHistory);
  }

  void _saveToLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? existing = prefs.getString('chat_sessions');
    List<dynamic> sessions = existing != null ? jsonDecode(existing) : [];
    
    int curIdx = sessions.indexWhere((s) => s['id'] == _sessionId);
    if (curIdx >= 0) {
      sessions[curIdx]['messages'] = _messagesUI;
    } else {
      sessions.add({'id': _sessionId, 'date': _sessionId, 'messages': _messagesUI});
    }
    await prefs.setString('chat_sessions', jsonEncode(sessions));
  }

  void _kirimPesan() async {
    if (_msgController.text.trim().isEmpty) return;
    String userText = _msgController.text.trim();
    
    setState(() {
      _messagesUI.add({'sender': 'user', 'text': userText}); // Menggunakan add()
      _isLoading = true;
      _msgController.clear();
    });
    
    _scrollToBottom(); // Scroll saat kirim
    _saveToLocalStorage();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': userText, 'history': _historyGemini}),
      );

      if (!mounted) return; 

      if (response.statusCode == 200) {
        final dataJson = jsonDecode(response.body);
        String balas = dataJson['reply'] ?? 'Terjadi kebisuan Server AI';
        
        setState(() => _messagesUI.add({'sender': 'ai', 'text': balas}));
        _historyGemini.add({'role': 'user', 'parts': [{'text': userText}]});
        _historyGemini.add({'role': 'model', 'parts': [{'text': balas}]});
        _saveToLocalStorage();
        _scrollToBottom(); // Scroll saat AI membalas
      } else {
        setState(() => _messagesUI.add({'sender': 'error', 'text': 'Waduh, Server Backend menolak pesan. Detail: ${response.statusCode}'}));
        _saveToLocalStorage();
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return; 
      
      setState(() => _messagesUI.add({'sender': 'error', 'text': 'Koneksi ke server pusat Laravel terputus. Nyalakan server lalu coba lagi.'}));
      _saveToLocalStorage();
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgStart, _bgMid, _bgEnd],
          ),
        ),
        child: SafeArea(
          bottom: false, 
          child: Column(
            children: [
              _buildAppBar(),
              
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: false, // MATIKAN REVERSE AGAR MULAI DARI ATAS
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 140), 
                  itemCount: _messagesUI.length,
                  itemBuilder: (context, index) {
                    return _buildPesanBubble(_messagesUI[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      
      bottomSheet: Container(
        color: _surfaceLowest.withValues(alpha: 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) _buildLoadingIndicator(),
            if (_messagesUI.length <= 2) _buildSuggestionPills(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET COMPONENTS
  // =========================================================================

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surfaceLowest.withValues(alpha: 0.7),
        border: Border(bottom: BorderSide(color: _surfaceHigh)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: _onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _surfaceLowest, width: 2),
                      boxShadow: [
                        BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    child: _buildAvatarImage(),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: _surfaceLowest, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kila AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _onSurface)),
                  Text('Online • Ready to help', style: TextStyle(fontSize: 12, color: _secondary)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.history, color: _onSurfaceVariant),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotHistoryPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    return ClipOval(
      child: Image.asset(
        _kilaAvatarPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: _primaryFixed,
            child: Icon(Icons.smart_toy, color: _primary),
          );
        },
      ),
    );
  }

  Widget _buildPesanBubble(Map<String, String> msg) {
    bool isUser = msg['sender'] == 'user';
    bool isError = msg['sender'] == 'error';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12, bottom: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _surfaceHigh),
              ),
              child: _buildAvatarImage(),
            ),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isUser ? _primary : (isError ? Colors.red.shade50 : _surfaceLowest),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: isUser ? const Radius.circular(24) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(24),
                ),
                border: isUser ? null : Border.all(color: _surfaceHigh),
                boxShadow: [
                  if (!isUser) BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))
                ],
              ),
              child: isUser
                  ? Text(
                      msg['text']!,
                      style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                    )
                  : MarkdownBody(
                      data: msg['text']!,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: isError ? Colors.red : _onSurface, fontSize: 16, height: 1.5),
                        strong: TextStyle(color: isError ? Colors.red : _onSurface, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionPills() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('SUGGESTED FOR YOU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _onSurfaceVariant, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildPill('Apa MPASI yang bagus untuk usia 8 bulan?', Icons.restaurant),
              _buildPill('Berapa berat badan ideal anak?', Icons.monitor_weight),
              _buildPill('Jadwal imunisasi bayi bulan ini', Icons.vaccines),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String text, IconData icon) {
    return GestureDetector(
      onTap: () {
        _msgController.text = text;
        _kirimPesan();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 250,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _surfaceLowest,
          border: Border.all(color: _surfaceHigh),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _primaryFixed.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: _primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _onSurface)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
          const SizedBox(width: 12),
          Text('Kila sedang berpikir...', style: TextStyle(color: _onSurfaceVariant, fontSize: 13, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24), 
      decoration: BoxDecoration(
        color: _surfaceLowest.withValues(alpha: 0.85),
        border: Border(top: BorderSide(color: _surfaceHigh)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                style: TextStyle(fontSize: 16, color: _onSurface),
                decoration: InputDecoration(
                  hintText: 'Tanya Kila...',
                  hintStyle: TextStyle(color: _onSurfaceVariant.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: _surfaceLowest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: _surfaceHigh)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: _primaryContainer, width: 2)),
                ),
                onSubmitted: (value) => _kirimPesan(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isLoading ? null : _kirimPesan,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}