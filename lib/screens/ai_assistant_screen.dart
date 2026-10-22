import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/ai_service.dart';
import '../services/api/ai_api_service.dart';
import '../services/api/base_api_service.dart';
import 'package:provider/provider.dart';
import '../providers/taxi_demo_provider.dart';
import '../models/demo_ride_model.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add({
      'role': 'assistant',
      'text':
          '🌍 Selam! I\'m the Sidama Way Go assistant.\n\nI answer from live system data about:\n🚉 Stations and routes\n💰 Official fares and their source\n🚕 Station queues\n🎫 Your recent tickets\n📝 Your citizen reports\n\nI am read-only: I cannot buy, cancel or verify tickets, or change reports. You can also ask in Amharic or Sidaamu Afoo.',
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final taxiDemo = Provider.of<TaxiDemoProvider>(context, listen: false);

    // DEMO MODE: Intercept taxi queries for immediate response
    if (taxiDemo.status != DemoRideStatus.idle) {
      final lowercaseText = text.toLowerCase();

      if ((lowercaseText.contains('where') ||
              lowercaseText.contains('location')) &&
          (lowercaseText.contains('taxi') ||
              lowercaseText.contains('cab') ||
              lowercaseText.contains('ride'))) {
        final statusText = switch (taxiDemo.status) {
          DemoRideStatus.matched => 'has been found and is ready for you.',
          DemoRideStatus.approaching => 'is on the way to pick you up.',
          DemoRideStatus.arrived => 'has arrived at your location!',
          DemoRideStatus.inProgress =>
            'is currently in transit to ${taxiDemo.destination?.name}.',
          DemoRideStatus.completed => 'has successfully completed the trip.',
          _ => 'is being matched.',
        };

        final eta = taxiDemo.status != DemoRideStatus.completed
            ? ' Current ETA is ${taxiDemo.etaMinutes} minutes.'
            : '';
        final response =
            'DEMO: Your taxi (${taxiDemo.selectedTaxi?.id ?? 'N/A'}) $statusText$eta';

        setState(() {
          _messages.add({'role': 'assistant', 'text': response});
          _isLoading = false;
        });
        _scrollToBottom();
        await _tts.speak(response);
        return;
      }

      if ((lowercaseText.contains('how much') ||
              lowercaseText.contains('fare') ||
              lowercaseText.contains('price') ||
              lowercaseText.contains('cost')) &&
          (lowercaseText.contains('taxi') ||
              lowercaseText.contains('ride') ||
              lowercaseText.contains('trip') ||
              lowercaseText.contains('piazza'))) {
        final dest = taxiDemo.destination?.name ?? "your destination";
        final response =
            "DEMO: The estimated fare for your trip to $dest is ${taxiDemo.estimatedFare.toStringAsFixed(0)} ETB.";

        setState(() {
          _messages.add({'role': 'assistant', 'text': response});
          _isLoading = false;
        });
        _scrollToBottom();
        await _tts.speak(response);
        return;
      }

      if (lowercaseText.contains('arrived') &&
          (lowercaseText.contains('taxi') || lowercaseText.contains('my'))) {
        final response = taxiDemo.status == DemoRideStatus.arrived
            ? "DEMO: Yes, your taxi has arrived and is waiting for you at the pickup point."
            : "DEMO: No, your taxi is still ${taxiDemo.distanceRemainingKm.toStringAsFixed(1)} km away. ETA: ${taxiDemo.etaMinutes} min.";

        setState(() {
          _messages.add({'role': 'assistant', 'text': response});
          _isLoading = false;
        });
        _scrollToBottom();
        await _tts.speak(response);
        return;
      }
    }

    final aiService = NextJSAIServiceImpl();

    // Inject Taxi Demo Context for general AI awareness
    String systemContext = "";
    if (taxiDemo.status != DemoRideStatus.idle) {
      systemContext =
          ' [DEMO CONTEXT: User is currently in a Public Taxi Demo. Status: ${taxiDemo.status.name}. '
          'Pickup: ${taxiDemo.pickup?.name}, Destination: ${taxiDemo.destination?.name}, '
          'Taxi: ${taxiDemo.selectedTaxi?.id}, Fare: ${taxiDemo.estimatedFare} ETB.]';
    }

    // The backend expects history to start with a 'user' message.
    // We skip the first 'assistant' welcome message.
    final history = _messages
        .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
        .toList();

    if (history.isNotEmpty && history.first['role'] == 'assistant') {
      history.removeAt(0);
    }
    // Remove the last message because it's the current user message being sent as the third argument
    if (history.isNotEmpty && history.last['text'] == text) {
      history.removeLast();
    }

    String response;
    try {
      response = await aiService.chat(
        systemContext + text,
        _selectedLang,
        history: history,
      );
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : AIApiService.unavailableMessage;
      setState(() {
        _messages.add({'role': 'assistant', 'text': message});
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _messages.add({'role': 'assistant', 'text': response});
      _isLoading = false;
    });
    _scrollToBottom();

    // Speak the response
    await _tts.setLanguage(_selectedLang == 'am' ? 'am-ET' : 'en-US');
    await _tts.speak(response);
  }

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

  Future<void> _startListening() async {
    bool available = await _stt.initialize();
    if (available) {
      setState(() => _isListening = true);
      await _stt.listen(
        onResult: (result) {
          setState(() => _controller.text = result.recognizedWords);
        },
        listenOptions: SpeechListenOptions(
          localeId: _selectedLang == 'am' ? 'am_ET' : 'en_US',
        ),
      );
    }
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'AI Assistant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Language selector
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                _langBtn('EN', 'en'),
                _langBtn('አማ', 'am'),
                _langBtn('Sid', 'sid'),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickBtn('🚉 Stations'),
                  _quickBtn('🚌 Routes'),
                  _quickBtn('💰 Fares'),
                  _quickBtn('🚕 Queues'),
                  _quickBtn('🎫 My tickets'),
                  _quickBtn('📝 My reports'),
                ],
              ),
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['text']!, isUser);
              },
            ),
          ),

          // Input area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _selectedLang == 'am'
                          ? 'ጠይቅ...'
                          : _selectedLang == 'sid'
                          ? 'Woy...'
                          : 'Ask about Hawassa...',
                      filled: true,
                      fillColor: const Color(0xFFF0F4F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                // Mic button
                GestureDetector(
                  onLongPressStart: (_) => _startListening(),
                  onLongPressEnd: (_) => _stopListening(),
                  child: CircleAvatar(
                    backgroundColor: _isListening
                        ? Colors.red
                        : Colors.grey[300],
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                CircleAvatar(
                  backgroundColor: const Color(0xFF2E7D32),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _langBtn(String label, String code) {
    final isSelected = _selectedLang == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLang = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _quickBtn(String label) {
    return GestureDetector(
      onTap: () {
        _controller.text = label.split(' ').skip(1).join(' ');
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20)),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2E7D32),
              child: const Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: () async {
                // Tap message to speak it
                await _tts.setLanguage(
                  _selectedLang == 'am' ? 'am-ET' : 'en-US',
                );
                await _tts.speak(text);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight: isUser ? const Radius.circular(4) : null,
                    bottomLeft: isUser ? null : const Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF2E7D32),
            child: Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thinking',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 24,
                  height: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (i) => Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}
