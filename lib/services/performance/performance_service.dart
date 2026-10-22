import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../core/utils/logger.dart';
import '../offline/offline_service.dart';

// Uint8List is already imported from dart:typed_data

class PerformanceService {
  static PerformanceService? _instance;
  final OfflineService _offlineService = OfflineService.instance;
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, List<dynamic>> _debounceQueues = {};

  static PerformanceService get instance {
    _instance ??= PerformanceService._();
    return _instance!;
  }

  PerformanceService._();

  // Lazy loading for lists
  Future<List<T>> loadLazy<T>({
    required Future<List<T>> Function(int offset, int limit) dataFetcher,
    required int pageSize,
    int initialOffset = 0,
  }) async {
    try {
      final data = await dataFetcher(initialOffset, pageSize);
      
      // Cache the loaded data
      final cacheKey = 'lazy_${T.toString()}_$initialOffset';
      await _offlineService.cacheData(cacheKey, data, expiry: const Duration(minutes: 5));
      
      return data;
    } catch (e) {
      AppLogger.error('Lazy loading failed', error: e);
      return [];
    }
  }

  Future<PaginatedData<T>> loadPaginated<T>({
    required Future<List<T>> Function(int page, int limit) dataFetcher,
    required int page,
    required int limit,
    required int totalItems,
  }) async {
    try {
      final offset = (page - 1) * limit;
      final items = await dataFetcher(offset, limit);
      
      final totalPages = (totalItems / limit).ceil();
      final hasMore = page < totalPages;

      // Cache the page
      final cacheKey = 'page_${T.toString()}_$page';
      await _offlineService.cacheData(cacheKey, items, expiry: const Duration(minutes: 10));

      return PaginatedData(
        items: items,
        currentPage: page,
        totalPages: totalPages,
        totalItems: totalItems,
        hasMore: hasMore,
      );
    } catch (e) {
      AppLogger.error('Pagination failed', error: e);
      return PaginatedData(
        items: [],
        currentPage: page,
        totalPages: 0,
        totalItems: 0,
        hasMore: false,
      );
    }
  }

  // Response caching
  Future<T?> getCachedResponse<T>(String key) async {
    return await _offlineService.getCachedData<T>(key);
  }

  Future<void> cacheResponse<T>(String key, T data, {Duration? expiry}) async {
    await _offlineService.cacheData(key, data, expiry: expiry);
  }

  // Debouncing
  void debounce<T>({
    required String key,
    required T Function() action,
    required Duration delay,
    void Function(T)? callback,
  }) {
    // Cancel existing timer
    _debounceTimers[key]?.cancel();
    
    // Add to queue
    if (!_debounceQueues.containsKey(key)) {
      _debounceQueues[key] = [];
    }
    _debounceQueues[key]!.add(action);
    
    // Set new timer
    _debounceTimers[key] = Timer(delay, () {
      // Execute all queued actions
      final queue = _debounceQueues[key] ?? [];
      _debounceQueues[key] = [];
      
      for (final action in queue) {
        try {
          final result = action();
          if (callback != null) {
            callback(result);
          }
        } catch (e) {
          AppLogger.error('Debounced action failed', error: e);
        }
      }
      
      // Clean up
      _debounceTimers.remove(key);
    });
  }

  // Image caching
  Future<void> cacheImage(String url, Uint8List imageData) async {
    final cacheKey = 'image_${url.hashCode}';
    await _offlineService.cacheData(cacheKey, imageData, expiry: const Duration(days: 7));
  }

  Future<Uint8List?> getCachedImage(String url) async {
    final cacheKey = 'image_${url.hashCode}';
    return await _offlineService.getCachedData<Uint8List>(cacheKey);
  }

  // Memory optimization
  void clearMemoryCache() {
    _debounceTimers.forEach((key, timer) => timer.cancel());
    _debounceTimers.clear();
    _debounceQueues.clear();
    AppLogger.info('Memory cache cleared');
  }

  // Viewport rendering optimization
  bool shouldRenderItem(int index, {
    required int firstVisibleIndex,
    required int lastVisibleIndex,
    int buffer = 5,
  }) {
    return index >= (firstVisibleIndex - buffer) && 
           index <= (lastVisibleIndex + buffer);
  }

  // Background processing
  Future<T> processInBackground<T>({
    required Future<T> Function() computation,
    Duration? timeout,
  }) async {
    try {
      if (timeout != null) {
        return await computation().timeout(timeout);
      }
      return await computation();
    } catch (e) {
      AppLogger.error('Background processing failed', error: e);
      rethrow;
    }
  }

  // Realtime optimization
  Stream<T> optimizedRealtimeStream<T>({
    required Stream<T> stream,
    Duration? throttle,
    Duration? debounce,
  }) {
    // Note: Custom throttle/debounce not implemented due to Stream API limitations
    // Stream operations can be added using rxdart package if needed
    return stream;
  }

  // Batch operations
  Future<List<T>> batchOperations<T>({
    required List<Future<T>> operations,
    int batchSize = 10,
    Duration? delayBetweenBatches,
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(batch);
      results.addAll(batchResults);
      
      if (delayBetweenBatches != null && i + batchSize < operations.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }
    
    return results;
  }

  // Performance monitoring
  final List<PerformanceMetrics> _metrics = [];

  Future<T> trackPerformance<T>({
    required String operation,
    required Future<T> Function() computation,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startTime = DateTime.now();
    
    try {
      final result = await computation();
      stopwatch.stop();
      
      _metrics.add(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        dataSize: result.toString().length,
        timestamp: startTime,
      ));
      
      // Keep only last 100 metrics
      if (_metrics.length > 100) {
        _metrics.removeAt(0);
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _metrics.add(PerformanceMetrics(
        operation: operation,
        duration: stopwatch.elapsed,
        dataSize: 0,
        timestamp: startTime,
      ));
      rethrow;
    }
  }

  List<PerformanceMetrics> getMetrics({String? operation}) {
    if (operation != null) {
      return _metrics.where((m) => m.operation == operation).toList();
    }
    return List.from(_metrics);
  }

  double getAverageDuration(String operation) {
    final operationMetrics = getMetrics(operation: operation);
    if (operationMetrics.isEmpty) return 0.0;
    
    final totalDuration = operationMetrics.fold<int>(
      0, (sum, m) => sum + m.duration.inMilliseconds,
    );
    
    return totalDuration / operationMetrics.length;
  }

  // Memory usage monitoring
  int getMemoryUsage() {
    // In production, use dart:developer to get actual memory usage
    return _metrics.length * 100; // Placeholder
  }

  // Performance recommendations
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    
    // Check average durations
    for (final operation in ['fetch_users', 'fetch_vehicles', 'fetch_trips']) {
      final avgDuration = getAverageDuration(operation);
      if (avgDuration > 1000) {
        recommendations.add('$operation is slow (${avgDuration.toStringAsFixed(0)}ms avg). Consider caching or pagination.');
      }
    }
    
    // Check memory usage
    final memoryUsage = getMemoryUsage();
    if (memoryUsage > 50000000) { // 50MB
      recommendations.add('High memory usage detected. Consider clearing cache.');
    }
    
    return recommendations;
  }

  // Optimized list builder
  Widget buildOptimizedList<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    required int itemCount,
    ScrollController? scrollController,
    bool shrinkWrap = false,
    EdgeInsets? padding,
    String? cacheKey,
  }) {
    // This would return a ListView.builder with optimizations
    // For now, return a placeholder
    return const SizedBox.shrink();
  }

  // Cleanup
  void dispose() {
    clearMemoryCache();
    _metrics.clear();
  }
}

// Pagination data class
class PaginatedData<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasMore;

  PaginatedData({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasMore,
  });
}

// Performance metrics class
class PerformanceMetrics {
  final String operation;
  final Duration duration;
  final int dataSize;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.operation,
    required this.duration,
    required this.dataSize,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'data_size': dataSize,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}