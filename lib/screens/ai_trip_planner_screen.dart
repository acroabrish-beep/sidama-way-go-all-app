import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/language_provider.dart';

class AITripPlannerScreen extends StatefulWidget {
  const AITripPlannerScreen({super.key});

  @override
  State<AITripPlannerScreen> createState() => _AITripPlannerScreenState();
}

class _AITripPlannerScreenState extends State<AITripPlannerScreen> {
  int _days = 1;
  String _budget = 'Medium';
  final List<String> _selectedInterests = [];
  bool _generating = false;
  String? _itinerary;

  final List<String> _interests = [
    'Nature', 'Culture', 'Food', 'Adventure', 'Relaxation', 'History'
  ];

  String _t(LanguageProvider lang, String en, String am, String sid) {
    if (lang.currentLang == 'am') return am;
    if (lang.currentLang == 'sid') return sid;
    return en;
  }

  void _generateItinerary(LanguageProvider lang) {
    setState(() => _generating = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _generating = false;
        _itinerary = _buildItineraryText(lang);
      });
    });
  }

  String _buildItineraryText(LanguageProvider lang) {
    String text = "${_t(lang, 'AI Generated Plan for', 'ለ', 'AI Generated Plan for')} $_days ${_t(lang, 'Day(s) in Hawassa', 'ቀናት የሀዋሳ የጉዞ እቅድ', 'Day(s) in Hawassa')}:\n\n";

    for (int i = 1; i <= _days; i++) {
      text += "${_t(lang, 'Day', 'ቀን', 'Day')} $i:\n";
      if (i == 1) {
        text += _t(lang,
          "- Morning: Breakfast at Piazza, then head to Amora Gedel Park to see the monkeys and birdlife.\n- Afternoon: Visit the Fish Market for fresh tilapia and a boat ride on Lake Hawassa.\n- Evening: Dinner at Haile Resort with a beautiful sunset view.\n\n",
          "- ጠዋት፡ ፒያሳ ቁርስ፣ ከዚያም ዝንጀሮዎችንና አእዋፍን ለማየት ወደ አሞራ ገደል ፓርክ።\n- ከሰዓት በኋላ፡ ትኩስ ቲላፒያ ለመቅመስ ዓሳ ገበያን ይጎብኙ እና በሀዋሳ ሐይቅ ላይ በጀልባ ይሳፈሩ።\n- ምሽት፡ በሀይሌ ሪዞርት የሚያምር የፀሐይ መግቢያን እየተመለከቱ እራት ይብሉ።\n\n",
          "- Morning: Breakfast at Piazza, then head to Amora Gedel Park to see the monkeys and birdlife.\n- Afternoon: Visit the Fish Market for fresh tilapia and a boat ride on Lake Hawassa.\n- Evening: Dinner at Haile Resort with a beautiful sunset view.\n\n"
        );
      } else if (i == 2) {
        text += _t(lang,
          "- Morning: Hike up Tabor Mountain for a panoramic view of the city.\n- Afternoon: Explore the Sidama Cultural Center and learn about local traditions.\n- Evening: Relax at a local cafe and try Sidama coffee.\n\n",
          "- ጠዋት፡ የከተማዋን ሰፊ እይታ ለማየት ወደ ታቦር ተራራ ይውጡ።\n- ከሰዓት በኋላ፡ የሲዳማ የባህል ማዕከልን ይጎብኙ እና ስለ አካባቢው ወግ ይማሩ።\n- ምሽት፡ በአካባቢው ካፌ ዘና ይበሉ እና የሲዳማ ቡና ይሞክሩ።\n\n",
          "- Morning: Hike up Tabor Mountain for a panoramic view of the city.\n- Afternoon: Explore the Sidama Cultural Center and learn about local traditions.\n- Evening: Relax at a local cafe and try Sidama coffee.\n\n"
        );
      } else {
        text += _t(lang,
          "- Morning: Trip to nearby Aleta Wondo or relaxation by the lake.\n- Afternoon: Souvenir shopping and visiting local galleries.\n- Evening: Farewell dinner at a traditional restaurant.\n\n",
          "- ጠዋት፡ ወደ አሌታ ወንዶ ጉዞ ወይም በሐይቁ ዳርቻ ዘና ማለት።\n- ከሰዓት በኋላ፡ የመታሰቢያ ዕቃዎችን መግዛት እና የአካባቢውን ጋለሪዎች መጎብኘት።\n- ምሽት፡ በባህላዊ ምግብ ቤት የመሰናበቻ እራት።\n\n",
          "- Morning: Trip to nearby Aleta Wondo or relaxation by the lake.\n- Afternoon: Souvenir shopping and visiting local galleries.\n- Evening: Farewell dinner at a traditional restaurant.\n\n"
        );
      }
    }

    text += "${_t(lang, 'Budget Level', 'የበጀት ደረጃ', 'Budget Level')}: $_budget\n";
    text += "${_t(lang, 'Interests', 'ፍላጎቶች', 'Interests')}: ${_selectedInterests.join(', ')}\n";
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(lang, 'AI Trip Planner', 'የAI የጉዞ እቅድ', 'AI Trip Planner')),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_itinerary == null) ...[
                Text(
                  _t(lang, 'Create Your Perfect Trip', 'ምርጥ ጉዞዎን ያቅዱ', 'Create Your Perfect Trip'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(lang, 'Answer a few questions and our AI will build a personalized Hawassa itinerary for you.',
                    'ጥቂት ጥያቄዎችን ይመልሱ እና የእኛ AI ለሀዋሳ የግል የጉዞ እቅድ ያዘጋጅልዎታል።',
                    'Answer a few questions and our AI will build a personalized Hawassa itinerary for you.'),
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(_t(lang, 'Number of Days', 'የቀናት ብዛት', 'Number of Days')),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _days = _days > 1 ? _days - 1 : 1),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                          ),
                          Text('$_days', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () => setState(() => _days = _days < 7 ? _days + 1 : 7),
                            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildLabel(_t(lang, 'Budget', 'በጀት', 'Budget')),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'Economy', label: Text(_t(lang, 'Economy', 'ቆጣቢ', 'Economy'))),
                          ButtonSegment(value: 'Medium', label: Text(_t(lang, 'Medium', 'መካከለኛ', 'Medium'))),
                          ButtonSegment(value: 'Luxury', label: Text(_t(lang, 'Luxury', 'ቅንጡ', 'Luxury'))),
                        ],
                        selected: {_budget},
                        onSelectionChanged: (val) => setState(() => _budget = val.first),
                      ),
                      const SizedBox(height: 20),
                      _buildLabel(_t(lang, 'Interests', 'ፍላጎቶች', 'Interests')),
                      Wrap(
                        spacing: 8,
                        children: _interests.map((interest) {
                          final selected = _selectedInterests.contains(interest);
                          return FilterChip(
                            label: Text(interest),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedInterests.add(interest);
                                } else {
                                  _selectedInterests.remove(interest);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _generateItinerary(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _generating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_t(lang, 'GENERATE MY TRIP', 'የጉዞ እቅዴን አውጣ', 'Generate My Trip'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                _buildItineraryView(lang),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildItineraryView(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blue),
            const SizedBox(width: 8),
            Text(_t(lang, 'Your Hawassa Itinerary', 'የሀዋሳ የጉዞ እቅድዎ', 'Your Hawassa Itinerary'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 24),
        _buildCard(
          child: Text(
            _itinerary!,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _itinerary = null),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_t(lang, 'RE-PLAN', 'እንደገና ያቅዱ', 'Re-plan')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_t(lang, 'SAVE & FINISH', 'አስቀምጥ እና ጨርስ', 'Save & Finish')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
