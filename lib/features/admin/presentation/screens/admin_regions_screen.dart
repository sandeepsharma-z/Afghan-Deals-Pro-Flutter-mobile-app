import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/admin_dynamic_provider.dart';

const _kBlue = Color(0xFF2258A8);

class AdminRegionsScreen extends ConsumerStatefulWidget {
  const AdminRegionsScreen({super.key});

  @override
  ConsumerState<AdminRegionsScreen> createState() => _AdminRegionsScreenState();
}

class _AdminRegionsScreenState extends ConsumerState<AdminRegionsScreen> {
  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(allRegionsAdminProvider);

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
        title: Text('Regions & Cities',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: () => ref.invalidate(allRegionsAdminProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddRegionDialog(context),
      ),
      body: regionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kBlue)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Run the SQL setup from Admin Dashboard first.',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(allRegionsAdminProvider),
                  style: ElevatedButton.styleFrom(backgroundColor: _kBlue),
                  child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        data: (regions) {
          if (regions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off, size: 48, color: Color(0xFFCCCCCC)),
                  const SizedBox(height: 12),
                  Text('No regions added yet',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black45)),
                  const SizedBox(height: 4),
                  Text('Tap + to add a region',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.black38)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: regions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _RegionTile(
              region: regions[i],
              onEdit: () => _showEditRegionDialog(context, regions[i]),
              onDelete: () => _deleteRegion(context, regions[i]),
              onManageCities: () =>
                  _showCitiesSheet(context, regions[i]),
            ),
          );
        },
      ),
    );
  }

  void _showAddRegionDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String country = 'Afghanistan';
    const countries = [
      'Afghanistan',
      'UAE',
      'Saudi Arabia',
      'Qatar',
      'Oman',
      'Kuwait',
      'Germany',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Region',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Region name (e.g. Kabul)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: country,
                decoration: InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => country = v!),
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final existing =
                      ref.read(allRegionsAdminProvider).valueOrNull ?? [];
                  await ref.read(adminRepositoryProvider).addRegion(
                        name,
                        country,
                        existing.length,
                      );
                  ref.invalidate(allRegionsAdminProvider);
                  if (mounted) _snack('Region "$name" added', success: true);
                } catch (e) {
                  if (mounted) _snack('Error: $e');
                }
              },
              child: Text('Add', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRegionDialog(BuildContext context, AppRegion region) {
    final nameCtrl = TextEditingController(text: region.regionName);
    bool isActive = region.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit Region',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Region name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active',
                      style: GoogleFonts.poppins(fontSize: 13)),
                  Switch(
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                    activeColor: _kBlue,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(adminRepositoryProvider)
                      .updateRegion(region.id, name, isActive);
                  ref.invalidate(allRegionsAdminProvider);
                  if (mounted) _snack('Updated', success: true);
                } catch (e) {
                  if (mounted) _snack('Error: $e');
                }
              },
              child: Text('Save', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  void _showCitiesSheet(BuildContext context, AppRegion region) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CitiesSheet(
        region: region,
        onSaved: (cities) async {
          try {
            await ref
                .read(adminRepositoryProvider)
                .updateRegionCities(region.id, cities);
            ref.invalidate(allRegionsAdminProvider);
            if (mounted) _snack('Cities updated', success: true);
          } catch (e) {
            if (mounted) _snack('Error: $e');
          }
        },
      ),
    );
  }

  Future<void> _deleteRegion(BuildContext context, AppRegion region) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Region?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
            'Delete "${region.regionName}" and all its ${region.cities.length} cities?',
            style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: GoogleFonts.poppins(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteRegion(region.id);
      ref.invalidate(allRegionsAdminProvider);
      if (mounted) _snack('Deleted', success: true);
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

// ── Region tile ───────────────────────────────────────────────────────────────
class _RegionTile extends StatelessWidget {
  final AppRegion region;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageCities;
  const _RegionTile({
    required this.region,
    required this.onEdit,
    required this.onDelete,
    required this.onManageCities,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.location_on, color: _kBlue, size: 18),
        ),
        title: Text(region.regionName,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: region.isActive ? Colors.black87 : Colors.black38)),
        subtitle: Text(
            '${region.country} · ${region.cities.length} cities',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const Icon(Icons.expand_more, size: 18, color: Colors.black38),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (region.cities.isEmpty)
                  Text('No cities added',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.black38))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: region.cities
                        .map((c) => Chip(
                              label: Text(c,
                                  style: GoogleFonts.poppins(fontSize: 11)),
                              backgroundColor: const Color(0xFFF0F0F0),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onManageCities,
                    icon: const Icon(Icons.location_city, size: 16),
                    label: Text('Manage Cities',
                        style: GoogleFonts.poppins(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kBlue,
                      side: const BorderSide(color: _kBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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
}

// ── Cities sheet ──────────────────────────────────────────────────────────────
class _CitiesSheet extends StatefulWidget {
  final AppRegion region;
  final Future<void> Function(List<String>) onSaved;
  const _CitiesSheet({required this.region, required this.onSaved});

  @override
  State<_CitiesSheet> createState() => _CitiesSheetState();
}

class _CitiesSheetState extends State<_CitiesSheet> {
  late List<String> _cities;
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cities = List<String>.from(widget.region.cities);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.region.regionName,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Add city input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Add city name...',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: GoogleFonts.poppins(fontSize: 13),
                    onSubmitted: (_) => _addCity(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue, foregroundColor: Colors.white),
                  onPressed: _addCity,
                  child: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Cities list
            if (_cities.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.separated(
                  itemCount: _cities.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    leading: const Icon(Icons.location_city,
                        size: 16, color: Colors.black45),
                    title: Text(_cities[i],
                        style: GoogleFonts.poppins(fontSize: 13)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.red),
                      onPressed: () =>
                          setState(() => _cities.removeAt(i)),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No cities yet',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black38)),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Save Cities',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCity() {
    final city = _ctrl.text.trim();
    if (city.isEmpty || _cities.contains(city)) return;
    setState(() => _cities.add(city));
    _ctrl.clear();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSaved(_cities);
    if (mounted) Navigator.pop(context);
  }
}
