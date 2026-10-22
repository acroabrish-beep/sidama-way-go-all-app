import 'package:flutter/material.dart';
import '../services/ai_analytics_service.dart';
import '../services/api/base_api_service.dart';

class AIInsightsCard extends StatefulWidget {
  final String dashboardContext;
  final String title;

  const AIInsightsCard({
    super.key,
    required this.dashboardContext,
    this.title = '🤖 AI Smart Insights',
  });

  @override
  State<AIInsightsCard> createState() => _AIInsightsCardState();
}

class _AIInsightsCardState extends State<AIInsightsCard> {
  String _insights = '';
  bool _isLoading = false;
  bool _isExpanded = false;
  DateTime? _lastUpdated;

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    try {
      final insights = await AIAnalyticsService.generateInsights(
        dashboardContext: widget.dashboardContext,
      );
      setState(() {
        _insights = insights;
        _lastUpdated = DateTime.now();
        _isLoading = false;
        _isExpanded = true;
      });
    } catch (e) {
      setState(() {
        _insights = e is ApiException
            ? e.message
            : 'Unable to generate insights. Check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (_lastUpdated != null)
                          Text(
                            'Updated: ${_lastUpdated!.hour}:${_lastUpdated!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    onPressed: _isLoading ? null : _loadInsights,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Generate button if no insights yet
              if (_insights.isEmpty && !_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loadInsights,
                    icon: const Icon(Icons.analytics, color: Color(0xFF1B5E20)),
                    label: const Text(
                      'Generate AI Insights from Firebase Data',
                      style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

              // Loading state
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Reading Firebase data and generating insights...',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // Insights content
              if (_insights.isNotEmpty) ...[
                AnimatedCrossFade(
                  firstChild: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isExpanded
                              ? _insights
                              : _insights.length > 200
                                  ? '${_insights.substring(0, 200)}...'
                                  : _insights,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        if (_insights.length > 200) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(() => _isExpanded = !_isExpanded),
                            child: Text(
                              _isExpanded ? 'Show less ▲' : 'Read more ▼',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                  crossFadeState: _insights.isNotEmpty
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),

                const SizedBox(height: 8),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loadInsights,
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                        label: const Text('Refresh', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
