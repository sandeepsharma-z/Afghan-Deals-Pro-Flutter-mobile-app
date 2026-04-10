import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/sell_provider.dart';

// ── Static data ────────────────────────────────────────────────────────────────

const _kBlue = Color(0xFF2258A8);

const _kSubcategories = ['Used Cars', 'New Cars', 'Export Cars', 'Rental Cars'];

const _kMakes = [
  'Mercedes', 'Toyota', 'Nissan', 'Lexus', 'BMW', 'Ford', 'Kia',
  'Hyundai', 'Land Rover', 'Chevrolet', 'Dodge', 'Mitsubishi',
  'Honda', 'Audi', 'Porsche', 'Suzuki', 'Mazda', 'Isuzu',
  'Jeep', 'Volkswagen', 'Volvo', 'Peugeot', 'Renault', 'Other',
];

const _kModelMap = <String, List<String>>{
  'Mercedes': ['E Class', 'S Class', 'C Class', 'G Class', 'GLC', 'GLE', 'A Class', 'CLA', 'GLS', 'CLS', 'V Class', 'Other'],
  'Toyota':   ['Camry', 'Corolla', 'Land Cruiser', 'Hilux', 'Prado', 'RAV4', 'Yaris', 'Fortuner', 'Innova', 'Other'],
  'BMW':      ['3 Series', '5 Series', '7 Series', 'X3', 'X5', 'X7', 'M3', 'M5', 'Other'],
  'Nissan':   ['Patrol', 'Altima', 'Sunny', 'X-Trail', 'Pathfinder', 'Navara', 'Other'],
  'Lexus':    ['LX', 'GX', 'RX', 'ES', 'IS', 'LS', 'UX', 'Other'],
  'Hyundai':  ['Sonata', 'Elantra', 'Tucson', 'Santa Fe', 'Accent', 'Other'],
  'Kia':      ['Sportage', 'Sorento', 'Cerato', 'Optima', 'Carnival', 'Other'],
  'Honda':    ['Civic', 'Accord', 'CR-V', 'HR-V', 'City', 'Other'],
  'Ford':     ['F-150', 'Explorer', 'Escape', 'Mustang', 'Ranger', 'Other'],
  'Audi':     ['A4', 'A6', 'A8', 'Q5', 'Q7', 'Q8', 'Other'],
};

final _kYears = List.generate(
  DateTime.now().year - 1989,
  (i) => (DateTime.now().year - i).toString(),
);

const _kTransmissions = ['Automatic', 'Manual', 'CVT', 'Semi-Automatic'];
const _kFuelTypes     = ['Petrol', 'Diesel', 'Hybrid', 'Electric', 'CNG', 'LPG'];
const _kBodyTypes     = ['Sedan', 'SUV', 'Pickup / Truck', 'Hatchback', 'Van / Minivan', 'Coupe', 'Convertible', 'Wagon', 'Crossover', 'Other'];
const _kConditions    = ['New', 'Used', 'Certified Pre-Owned'];
const _kSellerTypes   = ['Individual', 'Dealer', 'Showroom'];
const _kColors        = ['White', 'Silver', 'Grey', 'Black', 'Red', 'Gold', 'Orange', 'Blue', 'Beige', 'Yellow', 'Purple', 'Green', 'Brown', 'Burgundy', 'Other'];
const _kCurrencies    = ['AFN', 'USD', 'AED', 'OMR', 'QAR', 'SAR', 'SYP', 'EUR', 'GBP', 'PKR'];

// ── Country model ──────────────────────────────────────────────────────────────

class _Country {
  final String name;
  final String flag;
  final List<String> cities;
  const _Country(this.name, this.flag, this.cities);
}

const _kCountries = [
  _Country('Afghanistan', 'assets/images/flags/afghanistan.png', [
    'Kabul', 'Kandahar', 'Herat', 'Mazar-e-Sharif', 'Jalalabad', 'Kunduz',
    'Ghazni', 'Faizabad', 'Taliqan', 'Charikar', 'Gardez', 'Khost',
    'Bamyan', 'Lashkar Gah', 'Zaranj', 'Sheberghan', 'Maimana', 'Aybak',
  ]),
  _Country('UAE', 'assets/images/flags/uae.png', [
    'Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Ras Al Khaimah',
    'Fujairah', 'Umm Al Quwain', 'Al Ain',
  ]),
  _Country('Oman', 'assets/images/flags/oman.png', [
    'Muscat', 'Salalah', 'Sohar', 'Nizwa', 'Sur', 'Ibri', 'Barka',
  ]),
  _Country('Qatar', 'assets/images/flags/qatar.png', [
    'Doha', 'Al Rayyan', 'Al Wakrah', 'Al Khor', 'Lusail',
  ]),
  _Country('KSA', 'assets/images/flags/ksa.png', [
    'Riyadh', 'Jeddah', 'Mecca', 'Medina', 'Dammam', 'Khobar', 'Tabuk',
    'Abha', 'Qassim', 'Taif',
  ]),
  _Country('Syria', 'assets/images/flags/syria.png', [
    'Damascus', 'Aleppo', 'Homs', 'Latakia', 'Hama', 'Deir ez-Zor',
  ]),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class PostCarScreen extends ConsumerStatefulWidget {
  const PostCarScreen({super.key});

  @override
  ConsumerState<PostCarScreen> createState() => _PostCarScreenState();
}

class _PostCarScreenState extends ConsumerState<PostCarScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _mileageCtrl = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _modelCtrl   = TextEditingController();
  final _cityCtrl    = TextEditingController();

  String    _subcategory  = '';
  String    _make         = '';
  String    _model        = '';
  String    _year         = '';
  String    _transmission = '';
  String    _fuelType     = '';
  String    _bodyType     = '';
  String    _condition    = '';
  String    _color        = '';
  String    _sellerType   = 'Individual';

  String    _currency     = 'AFN';
  _Country  _country      = _kCountries.first;

  String _normalizeSubcategory(String value) {
    final v = value.trim().toLowerCase();
    if (v.contains('used')) return 'used-cars';
    if (v.contains('new')) return 'new-cars';
    if (v.contains('export')) return 'export-cars';
    if (v.contains('rental')) return 'rental-cars';
    return v.replaceAll(' ', '-');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _mileageCtrl.dispose();
    _priceCtrl.dispose();
    _modelCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_condition.isEmpty) { _showError('Please select condition'); return; }

    await ref.read(sellProvider.notifier).createListing(
      category: 'cars',
      baseData: {
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price':       double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'currency':    _currency,
        'city':        _cityCtrl.text.trim(),
        'country':     _country.name,
        'subcategory': _normalizeSubcategory(_subcategory),
      },
      categoryData: {
        'make':         _make,
        'model':        _model,
        'year':         _year,
        'mileage':      _mileageCtrl.text.trim(),
        'transmission': _transmission,
        'fuel_type':    _fuelType,
        'body_type':    _bodyType,
        'condition':    _condition,
        'color':        _color,
        'seller_type':  _sellerType,
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Pickers ─────────────────────────────────────────────────────────────────

  void _showPicker(String title, List<String> options, ValueChanged<String> onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          const Divider(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) => InkWell(
                onTap: () { onSelect(options[i]); Navigator.pop(context); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Text(options[i],
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.black12,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('Select Country',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            const Divider(height: 1),
            ..._kCountries.map((c) => ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(c.flag, width: 32, height: 22, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.flag, size: 22)),
              ),
              title: Text(c.name, style: GoogleFonts.poppins(fontSize: 14)),
              selected: _country.name == c.name,
              selectedTileColor: AppColors.primaryLight,
              onTap: () {
                setState(() { _country = c; _cityCtrl.clear(); });
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.black12,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Text('Select Currency',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _kCurrencies.map((cur) => ListTile(
                    title: Text(cur, style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: cur == _currency ? FontWeight.w600 : FontWeight.w400)),
                    trailing: cur == _currency
                        ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                        : null,
                    onTap: () { setState(() => _currency = cur); Navigator.pop(context); },
                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sell = ref.watch(sellProvider);

    ref.listen(sellProvider, (_, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ad submitted. It will be visible after admin approval.',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
        ref.read(sellProvider.notifier).reset();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
      if (next.error != null) _showError(next.error!);
    });

    final models = _kModelMap[_make] ?? <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Post Car Ad',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photos ────────────────────────────────────────────────
              _CarPhotoSection(sell: sell),
              const SizedBox(height: 8),

              // ── Ad Type ───────────────────────────────────────────────
              _Section(title: 'Ad Type', children: [
                _Field(
                  label: 'Subcategory *',
                  child: _FullWidthChipGroup(
                    options: _kSubcategories,
                    selected: _subcategory,
                    onSelect: (v) => setState(() => _subcategory = v),
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              // ── Ad Details ────────────────────────────────────────────
              _Section(title: 'Ad Details', children: [
                _Field(
                  label: 'Title *',
                  child: _textInput(
                    controller: _titleCtrl,
                    hint: 'e.g. Toyota Land Cruiser 2022 GXR',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                  ),
                ),
                _Field(
                  label: 'Description',
                  child: _textInput(
                    controller: _descCtrl,
                    hint: 'Describe the car, condition, history...',
                    maxLines: 4,
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              // ── Car Details ───────────────────────────────────────────
              _Section(title: 'Car Details', children: [
                _Field(
                  label: 'Make (Brand)',
                  child: _DropdownTile(
                    value: _make.isEmpty ? 'Select make' : _make,
                    onTap: () => _showPicker('Make', _kMakes, (v) {
                      setState(() { _make = v; _model = ''; });
                    }),
                  ),
                ),
                _Field(
                  label: 'Model',
                  child: models.isNotEmpty
                      ? _DropdownTile(
                          value: _model.isEmpty ? 'Select model' : _model,
                          onTap: () => _showPicker('Model', models,
                              (v) => setState(() => _model = v)),
                        )
                      : _textInput(
                          controller: _modelCtrl,
                          hint: 'e.g. Corolla, Civic...',
                          onChanged: (v) => _model = v,
                        ),
                ),
                _Field(
                  label: 'Year',
                  child: _DropdownTile(
                    value: _year.isEmpty ? 'Select year' : _year,
                    onTap: () => _showPicker('Year', _kYears,
                        (v) => setState(() => _year = v)),
                  ),
                ),
                _Field(
                  label: 'Mileage (km)',
                  child: _textInput(
                    controller: _mileageCtrl,
                    hint: 'e.g. 45000',
                    keyboardType: TextInputType.number,
                  ),
                ),
                _Field(
                  label: 'Condition *',
                  child: _RowChipGroup(
                    options: _kConditions,
                    selected: _condition,
                    onSelect: (v) => setState(() => _condition = v),
                  ),
                ),
                _Field(
                  label: 'Transmission',
                  child: _RowChipGroup(
                    options: _kTransmissions,
                    selected: _transmission,
                    onSelect: (v) => setState(() => _transmission = v),
                  ),
                ),
                _Field(
                  label: 'Fuel Type',
                  child: _RowChipGroup(
                    options: _kFuelTypes,
                    selected: _fuelType,
                    onSelect: (v) => setState(() => _fuelType = v),
                  ),
                ),
                _Field(
                  label: 'Body Type',
                  child: _DropdownTile(
                    value: _bodyType.isEmpty ? 'Select body type' : _bodyType,
                    onTap: () => _showPicker('Body Type', _kBodyTypes,
                        (v) => setState(() => _bodyType = v)),
                  ),
                ),
                _Field(
                  label: 'Exterior Color',
                  child: _DropdownTile(
                    value: _color.isEmpty ? 'Select color' : _color,
                    onTap: () => _showPicker('Color', _kColors,
                        (v) => setState(() => _color = v)),
                  ),
                ),
                _Field(
                  label: 'Seller Type',
                  child: _RowChipGroup(
                    options: _kSellerTypes,
                    selected: _sellerType,
                    onSelect: (v) => setState(() => _sellerType = v),
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              // ── Price ─────────────────────────────────────────────────
              _Section(title: 'Price', children: [
                _Field(
                  label: 'Currency',
                  child: _DropdownTile(
                    value: _currency,
                    onTap: _showCurrencyPicker,
                  ),
                ),
                _Field(
                  label: 'Price *',
                  child: _textInput(
                    controller: _priceCtrl,
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Price is required'
                        : null,
                  ),
                ),
              ]),
              const SizedBox(height: 8),

              // ── Location ──────────────────────────────────────────────
              _Section(title: 'Location', children: [
                _Field(
                  label: 'Country',
                  child: GestureDetector(
                    onTap: _showCountryPicker,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.asset(_country.flag,
                                width: 28, height: 19, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.flag, size: 20)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_country.name,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.black87)),
                          ),
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.black45, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                _Field(
                  label: 'City *',
                  child: _textInput(
                    controller: _cityCtrl,
                    hint: 'e.g. Kabul, Dubai...',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'City is required'
                        : null,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),

      // ── Bottom submit ────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: sell.isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              disabledBackgroundColor: _kBlue.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: sell.isSubmitting
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text('Post Ad',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _textInput({
    TextEditingController? controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error)),
      ),
    );
  }
}

// ── Photo section ──────────────────────────────────────────────────────────────

class _CarPhotoSection extends ConsumerWidget {
  final SellState sell;
  const _CarPhotoSection({required this.sell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sellProvider.notifier);
    final images = sell.images;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Photos',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('${images.length}/10',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
            const Spacer(),
            if (images.length < 10)
              Text('${10 - images.length} more',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (images.length < 10)
                  GestureDetector(
                    onTap: () => _showImageSourceSheet(context, notifier),
                    child: Container(
                      width: 96, height: 96,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: _kBlue.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: _kBlue, size: 28),
                          const SizedBox(height: 4),
                          Text('Add Photo',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, fontWeight: FontWeight.w500,
                                  color: _kBlue)),
                        ],
                      ),
                    ),
                  ),
                ...images.asMap().entries.map((e) {
                  final idx = e.key;
                  final img = e.value;
                  return Stack(children: [
                    Container(
                      width: 96, height: 96,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                            image: FileImage(File(img.path)),
                            fit: BoxFit.cover),
                      ),
                    ),
                    if (idx == 0)
                      Positioned(
                        bottom: 0, left: 0, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          decoration: const BoxDecoration(
                            color: Color(0xCC000000),
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(10)),
                          ),
                          child: Text('Cover', textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 10,
                                  color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    Positioned(
                      top: 4, right: 12,
                      child: GestureDetector(
                        onTap: () => notifier.removeImage(idx),
                        child: Container(
                          width: 22, height: 22,
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ]);
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('First photo will be the cover. Tap + to add up to 10 photos.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38)),
        ],
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context, SellNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kBlue),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () { Navigator.pop(context); notifier.pickFromGallery(); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _kBlue),
              title: Text('Take a Photo',
                  style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () { Navigator.pop(context); notifier.pickFromCamera(); },
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Section ────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ── Field ──────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ── Dropdown tile ──────────────────────────────────────────────────────────────

class _DropdownTile extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _DropdownTile({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.startsWith('Select');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isPlaceholder ? Colors.black38 : Colors.black87)),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

// ── Full-width chip group (for subcategory) ────────────────────────────────────

class _FullWidthChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _FullWidthChipGroup(
      {required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isSelected ? _kBlue : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? _kBlue : const Color(0xFFDDDDDD)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(opt,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isSelected ? Colors.white : Colors.black87)),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: Colors.white, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Horizontal scrollable chip group (for condition, transmission, etc.) ───────

class _RowChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _RowChipGroup(
      {required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? _kBlue : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isSelected ? _kBlue : const Color(0xFFDDDDDD)),
              ),
              child: Text(opt,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.black87)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
