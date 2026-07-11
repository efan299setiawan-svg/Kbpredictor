import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/history_provider.dart';
import '../services/history_repository.dart';
import '../widgets/history_tile.dart';
import '../widgets/empty_state.dart';
import 'history_input_screen.dart';

/// Full history list with search, device/browser/result filters and
/// sortable columns.
class HistoryViewerScreen extends StatefulWidget {
  const HistoryViewerScreen({super.key});

  @override
  State<HistoryViewerScreen> createState() => _HistoryViewerScreenState();
}

class _HistoryViewerScreenState extends State<HistoryViewerScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters(BuildContext context) async {
    final history = context.read<HistoryProvider>();
    final devices = await history.distinctDevices();
    final browsers = await history.distinctBrowsers();
    if (!mounted) return;

    String? device = history.filterDevice;
    String? browser = history.filterBrowser;
    String? result = history.filterResult;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Filter History', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: device,
                    decoration: const InputDecoration(labelText: 'Device'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Devices')),
                      ...devices.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                    ],
                    onChanged: (v) => setModalState(() => device = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: browser,
                    decoration: const InputDecoration(labelText: 'Browser'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Browsers')),
                      ...browsers.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                    ],
                    onChanged: (v) => setModalState(() => browser = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: result,
                    decoration: const InputDecoration(labelText: 'Result'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Results')),
                      DropdownMenuItem(value: 'B', child: Text('B (Win)')),
                      DropdownMenuItem(value: 'K', child: Text('K (Loss)')),
                    ],
                    onChanged: (v) => setModalState(() => result = v),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            history.clearFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            history.updateFilters(device: device, browser: browser, result: result);
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortMenu(BuildContext context) {
    final history = context.read<HistoryProvider>();
    showMenu<HistorySortField>(
      context: context,
      position: const RelativeRect.fromLTRB(200, 100, 16, 0),
      items: HistorySortField.values
          .map((f) => PopupMenuItem(value: f, child: Text(_sortLabel(f))))
          .toList(),
    ).then((field) {
      if (field != null) {
        final ascending = history.sortField == field ? !history.sortAscending : false;
        history.updateSort(field, ascending);
      }
    });
  }

  String _sortLabel(HistorySortField f) {
    switch (f) {
      case HistorySortField.date:
        return 'Date';
      case HistorySortField.device:
        return 'Device';
      case HistorySortField.browser:
        return 'Browser';
      case HistorySortField.result:
        return 'Result';
      case HistorySortField.minute:
        return 'Minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final items = history.filteredAndSorted;
    final hasFilters = history.filterDevice != null ||
        history.filterBrowser != null ||
        history.filterResult != null ||
        history.searchText.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(icon: const Icon(Icons.sort), onPressed: () => _showSortMenu(context)),
          IconButton(
            icon: Icon(hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => _openFilters(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistoryInputScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: history.updateSearch,
              decoration: InputDecoration(
                hintText: 'Search device, browser, score...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: history.searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          history.updateSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${items.length} results', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                if (hasFilters)
                  TextButton(
                    onPressed: () {
                      history.clearFilters();
                      _searchController.clear();
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching history',
                    message: 'Try adjusting your search or filters.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final entry = items[i];
                      return Dismissible(
                        key: ValueKey(entry.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                        onDismissed: (_) => history.deleteEntry(entry.id!),
                        child: HistoryTile(
                          entry: entry,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => HistoryInputScreen(existing: entry)),
                          ),
                          onDelete: () => history.deleteEntry(entry.id!),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
