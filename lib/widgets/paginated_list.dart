import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaginatedFirestoreListView extends StatefulWidget {
  final Query query;
  final Widget Function(BuildContext, DocumentSnapshot) itemBuilder;
  final Widget? emptyWidget;
  final int pageSize;

  const PaginatedFirestoreListView({
    super.key,
    required this.query,
    required this.itemBuilder,
    this.emptyWidget,
    this.pageSize = 20,
  });

  @override
  State<PaginatedFirestoreListView> createState() => _PaginatedFirestoreListViewState();
}

class _PaginatedFirestoreListViewState extends State<PaginatedFirestoreListView> {
  final ScrollController _scrollController = ScrollController();
  final List<DocumentSnapshot> _docs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;

  @override
  void initState() {
    super.initState();
    _fetchNextBatch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchNextBatch();
      }
    }
  }

  Future<void> _fetchNextBatch() async {
    setState(() => _isLoading = true);

    Query currentQuery = widget.query.limit(widget.pageSize);
    if (_lastDoc != null) {
      currentQuery = currentQuery.startAfterDocument(_lastDoc!);
    }

    try {
      final snapshot = await currentQuery.get();
      if (snapshot.docs.length < widget.pageSize) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        _docs.addAll(snapshot.docs);
      }
    } catch (e) {
      debugPrint('Pagination error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_docs.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? const Center(child: Text('No data found'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _docs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _docs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return widget.itemBuilder(context, _docs[index]);
      },
    );
  }
}
