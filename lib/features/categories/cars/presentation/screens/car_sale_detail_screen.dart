import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../chat/presentation/providers/chat_provider.dart';
import '../../../../chat/presentation/screens/chat_detail_screen.dart';
import '../../../../../features/listings/data/models/car_sale_model.dart';

class CarSaleDetailScreen extends ConsumerStatefulWidget {
  final CarSaleModel car;
  const CarSaleDetailScreen({super.key, required this.car});

  @override
  ConsumerState<CarSaleDetailScreen> createState() => _CarSaleDetailScreenState();
}

class _CarSaleDetailScreenState extends ConsumerState<CarSaleDetailScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  bool _chatLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    if (widget.car.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % widget.car.images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentPage = next);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 312,
                    width: double.infinity,
                    child: car.images.isEmpty
                        ? Container(
                            color: const Color(0xFFE8E8E8),
                            child: const Icon(Icons.directions_car,
                                size: 50, color: Colors.grey),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: car.images.length,
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            itemBuilder: (_, i) => Image.network(
                              car.images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE8E8E8),
                                child: const Icon(Icons.directions_car,
                                    size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 21,
                        height: 21,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 12, color: Colors.black87),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x63000000),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              color: Colors.white, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentPage + 1}/${car.images.isEmpty ? 1 : car.images.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11.62,
                              fontWeight: FontWeight.w400,
                              height: 17.06 / 11.62,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (car.images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          car.images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: index == _currentPage ? 10 : 7,
                            height: index == _currentPage ? 10 : 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD9D9D9),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -14),
                      child: const Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TopCircleButton(icon: Icons.reply_outlined),
                            SizedBox(width: 10),
                            _TopCircleButton(icon: Icons.favorite_border),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      car.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 17.88,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 24.24 / 17.88,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      car.title,
                      style: GoogleFonts.poppins(
                        fontSize: 17.24,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF141414),
                        height: 31.04 / 17.24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _DetailSpec(icon: Icons.calendar_month_outlined, value: car.year.isEmpty ? '-' : car.year),
                        const SizedBox(width: 14),
                        _DetailSpec(icon: Icons.speed_outlined, value: car.mileage.isEmpty ? '-' : car.mileage),
                        const SizedBox(width: 14),
                        _DetailSpec(icon: Icons.public, value: car.transmission.isEmpty ? '-' : car.transmission),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Color(0xFF505050)),
                        const SizedBox(width: 5),
                        Text(
                          car.location.isNotEmpty ? car.location : 'Afghanistan',
                          style: GoogleFonts.poppins(
                            fontSize: 11.62,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF505050),
                            height: 17.06 / 11.62,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),
                    Text(
                      'Car Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 19.06,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 31.04 / 19.06,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _overviewRow('Condition', car.condition.isEmpty ? '-' : car.condition),
                    _overviewRow('Body Type', car.bodyType.isEmpty ? '-' : car.bodyType),
                    _overviewRow('Fuel Type', car.fuelType.isEmpty ? '-' : car.fuelType),
                    _overviewRow('Transmission', car.transmission.isEmpty ? '-' : car.transmission),
                    _overviewRow('Color', car.color.isEmpty ? '-' : car.color),
                    const SizedBox(height: 14),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _detailAction(Icons.phone_outlined, 'Call')),
                        const SizedBox(width: 8),
                        Expanded(child: _whatsAppAction(onTap: _openChat)),
                        const SizedBox(width: 8),
                        Expanded(child: _chatButton()),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              k,
              style: GoogleFonts.poppins(
                fontSize: 17.24,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 25.12 / 17.24,
              ),
            ),
          ),
          SizedBox(
            width: 132,
            child: Text(
              v,
              textAlign: TextAlign.left,
              style: GoogleFonts.poppins(
                fontSize: 17.24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 25.12 / 17.24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat() async {
    if (_chatLoading) return;
    setState(() => _chatLoading = true);
    try {
      final chatId = await ref.read(chatActionsProvider).openOrCreateChatForListing(
            listingId: widget.car.id,
            sellerId: widget.car.sellerId,
          );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatDetailScreen(chatId: chatId),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  Widget _chatButton() {
    return GestureDetector(
      onTap: _chatLoading ? null : _openChat,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: Center(
          child: _chatLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2258A8),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 16, color: Color(0xFF2258A8)),
                    const SizedBox(width: 8),
                    Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 14.24,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _detailAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2258A8)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.24,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 25.12 / 14.24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whatsAppAction({VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 16,
            color: Color(0xFF2258A8),
          ),
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  const _TopCircleButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF222222), size: 14),
    );
  }
}

class _DetailSpec extends StatelessWidget {
  final IconData icon;
  final String value;
  const _DetailSpec({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF505050)),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14.24,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF505050),
            height: 25.12 / 14.24,
          ),
        ),
      ],
    );
  }
}
