import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/admin_dynamic_provider.dart';

const _kBlue = Color(0xFF2258A8);

class AdminPriceSettingsScreen extends ConsumerStatefulWidget {
  const AdminPriceSettingsScreen({super.key});

  @override
  ConsumerState<AdminPriceSettingsScreen> createState() =>
      _AdminPriceSettingsScreenState();
}

class _AdminPriceSettingsScreenState
    extends ConsumerState<AdminPriceSettingsScreen> {
  final Map<String, TextEditingController> _maxCtrls = {};
  final Map<String, TextEditingController> _minCtrls = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final cat in kPriceCategories) {
      _maxCtrls[cat] = TextEditingController(
          text: kDefaultMaxPrices[cat] ?? '500000');
      _minCtrls[cat] = TextEditingController(text: '0');
    }
    _loadSettings();
  }

  @override
  void dispose() {
    for (final c in _maxCtrls.values) {
      c.dispose();
    }
    for (final c in _minCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(allAppSettingsProvider.future);
    for (final s in settings) {
      if (s.settingKey == 'max_price' && _maxCtrls.containsKey(s.category)) {
        _maxCtrls[s.category]!.text = s.settingValue;
      }
      if (s.settingKey == 'min_price' && _minCtrls.containsKey(s.category)) {
        _minCtrls[s.category]!.text = s.settingValue;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Price Settings',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: () {
              ref.invalidate(allAppSettingsProvider);
              _loadSettings();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Set the min/max price range for each category\'s filter slider. '
              'These values control the price slider limits shown to users.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.black54, height: 1.5),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: kPriceCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final cat = kPriceCategories[i];
                return _PriceCategoryCard(
                  category: cat,
                  maxCtrl: _maxCtrls[cat]!,
                  minCtrl: _minCtrls[cat]!,
                );
              },
            ),
          ),

          // Save button
          ColoredBox(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: _saving ? null : _saveAll,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Save All Settings',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      for (final cat in kPriceCategories) {
        final max = _maxCtrls[cat]!.text.trim();
        final min = _minCtrls[cat]!.text.trim();
        if (max.isNotEmpty) { await repo.upsertSetting(cat, 'max_price', max); }
        if (min.isNotEmpty) { await repo.upsertSetting(cat, 'min_price', min); }
      }
      ref.invalidate(allAppSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Settings saved!',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Price category card ───────────────────────────────────────────────────────
class _PriceCategoryCard extends StatelessWidget {
  final String category;
  final TextEditingController maxCtrl;
  final TextEditingController minCtrl;

  static const _icons = <String, IconData>{
    'cars': Icons.directions_car,
    'mobiles': Icons.phone_android,
    'electronics': Icons.devices,
    'furniture': Icons.chair,
    'jobs': Icons.work_outline,
    'properties': Icons.home_outlined,
    'spare_parts': Icons.build_outlined,
    'classifieds': Icons.sell_outlined,
  };

  static const _colors = <String, Color>{
    'cars': Color(0xFF1565C0),
    'mobiles': Color(0xFF00695C),
    'electronics': Color(0xFF6A1B9A),
    'furniture': Color(0xFF4E342E),
    'jobs': Color(0xFFE65100),
    'properties': Color(0xFF2E7D32),
    'spare_parts': Color(0xFF37474F),
    'classifieds': Color(0xFFC62828),
  };

  const _PriceCategoryCard({
    required this.category,
    required this.maxCtrl,
    required this.minCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _icons[category] ?? Icons.sell_outlined;
    final color = _colors[category] ?? const Color(0xFF2258A8);
    final label = category.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PriceField(
                  label: 'Min Price (AFN)',
                  controller: minCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PriceField(
                  label: 'Max Price (AFN)',
                  controller: maxCtrl,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _PriceField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.black45),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
      ),
    );
  }
}
