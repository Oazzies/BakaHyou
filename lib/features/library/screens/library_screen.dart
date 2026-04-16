import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/widgets/mb_search_bar.dart';
import 'package:bakahyou/features/library/models/library_entry.dart';
import 'package:bakahyou/features/library/services/library_service.dart';
import 'package:bakahyou/features/profile/services/profile_auth_service.dart';
import 'package:bakahyou/features/series/screens/series_detail_screen.dart';
import 'package:bakahyou/features/series/widgets/entry_list_item.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  final ProfileAuthService _auth = ProfileAuthService();
  late final LibraryService _libraryService = LibraryService(auth: _auth);

  final List<_LibraryTab> _tabs = const [
    _LibraryTab(key: 'reading', label: 'Reading'),
    _LibraryTab(key: 'paused', label: 'Paused'),
    _LibraryTab(key: 'completed', label: 'Completed'),
    _LibraryTab(key: 'plan_to_read', label: 'Plan to Read'),
    _LibraryTab(key: 'dropped', label: 'Dropped'),
    _LibraryTab(key: 'rereading', label: 'Rereading'),
    _LibraryTab(key: 'considering', label: 'Considering'),
  ];

  bool _loading = true;
  bool _loggedIn = false;
  String _query = '';
  String? _error;
  List<LibraryEntry> _allEntries = const [];

  late TabController _tabController;
  late final Map<String, ScrollController> _scrollControllers = {
    for (final tab in _tabs) tab.key: ScrollController(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hasSession = await _auth.hasSession();
      if (!hasSession) {
        if (!mounted) return;
        setState(() {
          _loggedIn = false;
          _allEntries = const [];
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _loggedIn = true;
      });

      await _loadAllLibraryEntries();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadAllLibraryEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entries = await _libraryService.fetchAllEntries();
      if (!mounted) return;
      setState(() {
        _allEntries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loginAndReload() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.login();
      if (!mounted) return;
      setState(() {
        _loggedIn = true;
      });
      await _loadAllLibraryEntries();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _normalizeState(String raw) {
    final state = raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

    switch (state) {
      case 'on_hold':
      case 'onhold':
        return 'paused';
      case 'complete':
        return 'completed';
      case 'plan':
      case 'planned':
      case 'planning':
      case 'to_read':
      case 'plantoread':
        return 'plan_to_read';
      case 'drop':
        return 'dropped';
      case 're_reading':
      case 're_read':
      case 'reread':
        return 'rereading';
      default:
        return state;
    }
  }

  List<LibraryEntry> _queryFilteredEntries() {
    if (_query.isEmpty) return _allEntries;

    return _allEntries.where((entry) {
      return entry.series.title.toLowerCase().contains(_query) ||
          entry.series.nativeTitle.toLowerCase().contains(_query) ||
          entry.series.romanizedTitle.toLowerCase().contains(_query);
    }).toList();
  }

  List<LibraryEntry> _entriesForTab(_LibraryTab tab) {
    final known = const {
      'reading',
      'paused',
      'completed',
      'plan_to_read',
      'dropped',
      'rereading',
      'considering',
    };

    return _queryFilteredEntries().where((entry) {
      final state = _normalizeState(entry.state);

      if (tab.key == 'considering') {
        return state == 'considering' || !known.contains(state);
      }

      return state == tab.key;
    }).toList();
  }

  Widget _buildTabContent(_LibraryTab tab) {
    final items = _entriesForTab(tab);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No entries in ${tab.label}.',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollControllers[tab.key],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SeriesDetailScreen(series: entry.series),
              ),
            );
          },
          child: EntryListItem(series: entry.series),
        );
      },
    );
  }

  Widget _buildBody() {
    if (!_loggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Log in to view your library.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loginAndReload,
                child: const Text('Login on MangaBaka'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadAllLibraryEntries,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: _tabs.map(_buildTabContent).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0a0a),
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 16,
        title: MBSearchBar(
          onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
          onSubmitted: (value) => setState(() => _query = value.trim().toLowerCase()),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF1b9f70),
          tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }
}

class _LibraryTab {
  final String key;
  final String label;

  const _LibraryTab({required this.key, required this.label});
}