import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/admin_dynamic_provider.dart';

const _kBlue = Color(0xFF2258A8);

class AdminFilterOptionsScreen extends ConsumerStatefulWidget {
  const AdminFilterOptionsScreen({super.key});

  @override
  ConsumerState<AdminFilterOptionsScreen> createState() =>
      _AdminFilterOptionsScreenState();
}

class _AdminFilterOptionsScreenState
    extends ConsumerState<AdminFilterOptionsScreen> {
  String _selectedCategory = 'electronics';
  String _selectedFilterType = 'condition';

  List<String> get _filterTypes =>
      kFilterTypesByCategory[_selectedCategory] ?? ['condition'];

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(allFilterOptionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Filter Options',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: () => ref.invalidate(allFilterOptionsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddDialog(context),
      ),
      body: Column(
        children: [
          // ── Selector bar ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                _DropRow(
                  label: 'Category',
                  value: _selectedCategory,
                  items: kFilterCategories,
                  onChanged: (v) => setState(() {
                    _selectedCategory = v!;
                    final types = kFilterTypesByCategory[v] ?? ['condition'];
                    _selectedFilterType = types.first;
                  }),
                ),
                const SizedBox(height: 8),
                _DropRow(
                  label: 'Filter Type',
                  value: _selectedFilterType,
                  items: _filterTypes,
                  onChanged: (v) => setState(() => _selectedFilterType = v!),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: optionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _kBlue)),
              error: (e, _) => _ErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(allFilterOptionsProvider),
              ),
              data: (all) {
                final filtered = all
                    .where((o) =>
                        o.category == _selectedCategory &&
                        o.filterType == _selectedFilterType)
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune, size: 48, color: Color(0xFFCCCCCC)),
                        const SizedBox(height: 12),
                        Text('No options added yet',
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.black45)),
                        const SizedBox(height: 4),
                        Text('Tap + to add filter values',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.black38)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _OptionTile(
                    option: filtered[i],
                    onEdit: () => _showEditDialog(context, filtered[i]),
                    onDelete: () => _deleteOption(context, filtered[i].id),
                    onToggle: (active) =>
                        _toggleActive(filtered[i], active),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Option',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: $_selectedCategory',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
            Text('Type: $_selectedFilterType',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Value (e.g. Excellent)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue, foregroundColor: Colors.white),
            onPressed: () async {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;
              Navigator.pop(context);
              await _add(val);
            },
            child: Text('Add', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, FilterOption option) {
    final ctrl = TextEditingController(text: option.value);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Option',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue, foregroundColor: Colors.white),
            onPressed: () async {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;
              Navigator.pop(context);
              await ref
                  .read(adminRepositoryProvider)
                  .updateFilterOption(option.id, val, option.isActive);
              ref.invalidate(allFilterOptionsProvider);
            },
            child: Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> _add(String value) async {
    try {
      final existing = ref.read(allFilterOptionsProvider).valueOrNull ?? [];
      final count = existing
          .where((o) =>
              o.category == _selectedCategory &&
              o.filterType == _selectedFilterType)
          .length;
      await ref.read(adminRepositoryProvider).addFilterOption(
            _selectedCategory,
            _selectedFilterType,
            value,
            count,
          );
      ref.invalidate(allFilterOptionsProvider);
      if (mounted) _snack('Added "$value"', success: true);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  Future<void> _deleteOption(BuildContext ctx, String id) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Delete?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('This option will be removed.',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: GoogleFonts.poppins(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteFilterOption(id);
      ref.invalidate(allFilterOptionsProvider);
      if (mounted) _snack('Deleted', success: true);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  Future<void> _toggleActive(FilterOption option, bool active) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateFilterOption(option.id, option.value, active);
      ref.invalidate(allFilterOptionsProvider);
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── Option tile ───────────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final FilterOption option;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;
  const _OptionTile({
    required this.option,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _kBlue.withValues(alpha: 0.1),
          child: Text(
            option.sortOrder.toString(),
            style: GoogleFonts.poppins(
                fontSize: 11, color: _kBlue, fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(option.value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: option.isActive ? Colors.black87 : Colors.black38)),
        subtitle: option.isActive
            ? null
            : Text('Inactive',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.red)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: option.isActive,
              onChanged: onToggle,
              activeColor: _kBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.black45),
              onPressed: onEdit,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: onDelete,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown row ──────────────────────────────────────────────────────────────
class _DropRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
        ),
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Error widget ──────────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Table not found. Run the SQL setup first.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(message,
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.black38),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue),
              child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
