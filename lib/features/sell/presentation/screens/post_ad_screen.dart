import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../listings/presentation/providers/listings_provider.dart';

class PostAdScreen extends ConsumerStatefulWidget {
  final String category;
  const PostAdScreen({super.key, required this.category});

  @override
  ConsumerState<PostAdScreen> createState() => _PostAdScreenState();
}

class _PostAdScreenState extends ConsumerState<PostAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _currency = 'AFN';
  String _region = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  String get _categoryLabel {
    switch (widget.category) {
      case 'cars':
        return 'Car';
      case 'properties':
        return 'Property';
      case 'mobiles':
        return 'Mobile';
      case 'electronics':
        return 'Electronics';
      case 'furniture':
        return 'Furniture';
      case 'spare_parts':
        return 'Spare Part';
      case 'jobs':
        return 'Job';
      default:
        return 'Item';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .maybeSingle();

    final data = {
      'category': widget.category,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text.trim()),
      'currency': _currency,
      'seller_id': user.id,
      'seller_name': profile?['name'] ?? '',
      'country': 'Afghanistan',
      'region': _region.isNotEmpty ? _region : null,
      'images': <String>[],
      'category_data': {},
    };

    await ref.read(sellNotifierProvider.notifier).createListing(data);
  }

  @override
  Widget build(BuildContext context) {
    final sellState = ref.watch(sellNotifierProvider);

    ref.listen(sellNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (id) {
          if (id != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ad posted successfully!',
                    style: GoogleFonts.montserrat()),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
            context.pop();
          }
        },
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString(), style: GoogleFonts.montserrat()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Post $_categoryLabel Ad',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            letterSpacing: 0,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos placeholder
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 36, color: Colors.black38),
                      SizedBox(height: 6),
                      Text('Add Photos',
                          style:
                              TextStyle(color: Colors.black45, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _label('Title *'),
              AppTextField(
                controller: _titleCtrl,
                hintText: 'e.g. Toyota Corolla 2020',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),

              _label('Description'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your item...',
                  hintStyle: const TextStyle(color: Colors.black38),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              _label('Price'),
              Row(
                children: [
                  // Currency toggle
                  GestureDetector(
                    onTap: () => setState(
                        () => _currency = _currency == 'AFN' ? 'USD' : 'AFN'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currency,
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      controller: _priceCtrl,
                      hintText: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _label('Region / City'),
              AppTextField(
                hintText: 'e.g. Kabul',
                onChanged: (v) => _region = v,
              ),
              const SizedBox(height: 32),

              AppButton(
                label: 'Post Ad',
                isLoading: sellState.isLoading,
                onTap: _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
      ),
    );
  }
}
