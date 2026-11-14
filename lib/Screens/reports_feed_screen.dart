import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportsFeedScreen extends StatefulWidget {
  final String userRole;

  const ReportsFeedScreen({super.key, required this.userRole});

  @override
  State<ReportsFeedScreen> createState() => _ReportsFeedScreenState();
}

class _ReportsFeedScreenState extends State<ReportsFeedScreen> {
  static const _sampleReports = [
    {
      'id': 'demo-water-leak',
      'title': 'Water pipeline leakage',
      'location': 'Cafeteria',
      'category': 'Facilities Issue',
      'description': 'Water is leaking near the cafeteria entrance.',
      'status': 'Waiting',
    },
    {
      'id': 'demo-library-power',
      'title': 'Power outage in the library',
      'location': 'Library, second floor',
      'category': 'Power Outage',
      'description': 'Lights and power outlets are not working.',
      'status': 'In Progress',
    },
    {
      'id': 'demo-elevator',
      'title': 'Elevator breakdown',
      'location': 'Learning Commons',
      'category': 'Safety concern',
      'description': 'The elevator is currently out of service.',
      'status': 'Completed',
    },
    {
      'id': 'demo-sanitation',
      'title': 'Sanitation bin overflow',
      'location': 'Student residence green area',
      'category': 'Sanitation',
      'description': 'A waste bin needs collection.',
      'status': 'Waiting',
    },
  ];

  final Map<String, String> _demoStatuses = {};
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'All';
  String _categoryFilter = 'All';
  String _archiveFilter = 'Active';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (widget.userRole != 'staff' && userId == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your reports.')),
      );
    }

    final reports = FirebaseFirestore.instance.collection('reports');
    final Query<Map<String, dynamic>> query = widget.userRole == 'staff'
        ? reports
        : reports.where('reporterUid', isEqualTo: userId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load reports: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reportDocuments = snapshot.data?.docs.toList() ?? [];
          reportDocuments.sort((a, b) {
            final first = _createdAt(a.data());
            final second = _createdAt(b.data());
            return second.compareTo(first);
          });
          final categories = {
            ...reportDocuments
                .map((report) => report.data()['category'])
                .whereType<String>(),
            ..._sampleReports
                .map((report) => report['category'])
                .whereType<String>(),
          }.toList()..sort();
          final selectedCategory =
              _categoryFilter == 'All' || categories.contains(_categoryFilter)
              ? _categoryFilter
              : 'All';
          final filteredReports = reportDocuments
              .where(
                (report) => _matchesFilters(
                  report.data(),
                  categoryFilter: selectedCategory,
                ),
              )
              .toList();
          final filteredSamples = _sampleReports.where((sample) {
            final data = {
              ...sample,
              'status': _demoStatuses[sample['id']!] ?? sample['status'],
            };
            return _matchesFilters(data, categoryFilter: selectedCategory);
          }).toList();
          if (reportDocuments.isEmpty && widget.userRole == 'staff') {
            return Column(
              children: [
                _buildFilters(categories),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (filteredSamples.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No reports match the selected filters.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final sample in filteredSamples)
                        _ReportCard(
                          data: {
                            ...sample,
                            'status':
                                _demoStatuses[sample['id']] ?? sample['status'],
                          },
                          isStaff: true,
                          onDemoStatusChanged: (status) {
                            setState(
                              () => _demoStatuses[sample['id']!] = status,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (reportDocuments.isEmpty) {
            return Column(
              children: [
                _buildFilters(categories),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'You have not submitted any reports yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildFilters(categories),
              Expanded(
                child: filteredReports.isEmpty
                    ? const Center(
                        child: Text('No reports match the selected filters.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          return _ReportCard(
                            data: report.data(),
                            isStaff: widget.userRole == 'staff',
                            reference: report.reference,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(List<String> categories) {
    final categoryValue =
        _categoryFilter == 'All' || categories.contains(_categoryFilter)
        ? _categoryFilter
        : 'All';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search reports',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All statuses')),
                    DropdownMenuItem(value: 'Waiting', child: Text('Waiting')),
                    DropdownMenuItem(
                      value: 'In Progress',
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'Completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _statusFilter = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: categoryValue,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All categories'),
                    ),
                    ...categories.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _categoryFilter = value);
                    }
                  },
                ),
              ),
            ],
          ),
          if (widget.userRole == 'staff') ...[
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Active', label: Text('Active')),
                ButtonSegment(value: 'Archived', label: Text('Archived')),
                ButtonSegment(value: 'All', label: Text('All')),
              ],
              selected: {_archiveFilter},
              onSelectionChanged: (selection) {
                setState(() => _archiveFilter = selection.first);
              },
            ),
          ],
        ],
      ),
    );
  }

  bool _matchesFilters(
    Map<String, dynamic> data, {
    required String categoryFilter,
  }) {
    final archived = data['archivedAt'] != null;
    final status = _normalizedStatus(data['status'] as String?);
    final category = data['category'] as String? ?? '';
    final search = _searchController.text.trim().toLowerCase();
    final searchableText = [
      data['title'],
      category,
      data['location'],
      data['description'],
    ].whereType<String>().join(' ').toLowerCase();

    if (widget.userRole == 'staff' && _archiveFilter == 'Active' && archived) {
      return false;
    }
    if (widget.userRole == 'staff' &&
        _archiveFilter == 'Archived' &&
        !archived) {
      return false;
    }
    if (_statusFilter != 'All' && status != _statusFilter) return false;
    if (categoryFilter != 'All' && category != categoryFilter) return false;
    return search.isEmpty || searchableText.contains(search);
  }

  String _normalizedStatus(String? storedStatus) {
    return switch (storedStatus?.toLowerCase()) {
      'pending review' || 'waiting' => 'Waiting',
      'in progress' => 'In Progress',
      'resolved' || 'completed' => 'Completed',
      _ => 'Waiting',
    };
  }

  DateTime _createdAt(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();
    if (createdAt is DateTime) return createdAt;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.data,
    required this.isStaff,
    this.reference,
    this.onDemoStatusChanged,
  });

  final Map<String, dynamic> data;
  final bool isStaff;
  final DocumentReference<Map<String, dynamic>>? reference;
  final ValueChanged<String>? onDemoStatusChanged;

  @override
  Widget build(BuildContext context) {
    final storedStatus = data['status'] as String? ?? 'Waiting';
    final status = switch (storedStatus.toLowerCase()) {
      'pending review' => 'Waiting',
      'resolved' => 'Completed',
      'waiting' => 'Waiting',
      'in progress' => 'In Progress',
      'completed' => 'Completed',
      _ => 'Waiting',
    };
    final color = switch (status.toLowerCase()) {
      'completed' => Colors.green,
      'in progress' => Colors.blue,
      _ => Colors.orange,
    };
    final imageUrl = data['imageUrl'] as String?;
    final isArchived = data['archivedAt'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['category'] as String? ?? 'Campus report',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data['title'] as String? ?? 'Untitled report',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['location'] as String? ?? 'Location not provided',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
            if (data['description'] is String &&
                (data['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(data['description'] as String),
            ],
            if (isStaff && data['reporterEmail'] is String) ...[
              const SizedBox(height: 8),
              Text(
                'Reported by ${data['reporterEmail']}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    alignment: Alignment.center,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Text('Photo could not be loaded'),
                  ),
                ),
              ),
            ],
            if (isStaff) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 190,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Change status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: status,
                        isExpanded: true,
                        onChanged: isArchived
                            ? null
                            : (newStatus) {
                                if (newStatus != null) {
                                  _updateStatus(context, newStatus);
                                }
                              },
                        items: const [
                          DropdownMenuItem(
                            value: 'Waiting',
                            child: Text('Waiting'),
                          ),
                          DropdownMenuItem(
                            value: 'In Progress',
                            child: Text('In Progress'),
                          ),
                          DropdownMenuItem(
                            value: 'Completed',
                            child: Text('Completed'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (reference != null && status == 'Completed')
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _setArchived(context, !isArchived),
                    icon: Icon(
                      isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    label: Text(
                      isArchived ? 'Restore report' : 'Archive report',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _setArchived(BuildContext context, bool archive) async {
    final reportReference = reference;
    if (reportReference == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(archive ? 'Archive completed report?' : 'Restore report?'),
        content: Text(
          archive
              ? 'The report will be hidden from the active staff feed but kept in Firestore. You can find it in Archived reports.'
              : 'The report will return to the active staff feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(archive ? 'Archive' : 'Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await reportReference.update({
        'archivedAt': archive ? FieldValue.serverTimestamp() : null,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            archive
                ? 'Report archived.'
                : 'Report restored to the active feed.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not ${archive ? 'archive' : 'restore'} report: '
            '${error.message ?? error.code}',
          ),
        ),
      );
    }
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    final reportReference = reference;
    if (reportReference == null) {
      onDemoStatusChanged?.call(status);
      return;
    }

    try {
      await reportReference.update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update report: ${error.message ?? error.code}',
          ),
        ),
      );
    }
  }
}
