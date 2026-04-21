import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../chat/presentation/providers/chat_provider.dart';
import '../../../../../features/listings/data/models/rental_car_model.dart';
import '../providers/rental_cars_provider.dart';

class CarResultsScreen extends ConsumerStatefulWidget {
  final String subcategory;
  final String
      rentalDuration; // 'all' | 'Daily Rentals' | 'Weekly Rentals' | 'Monthly Rentals'
  const CarResultsScreen({
    super.key,
    required this.subcategory,
    this.rentalDuration = 'all',
  });

  @override
  ConsumerState<CarResultsScreen> createState() => _CarResultsScreenState();
}

class _CarResultsScreenState extends ConsumerState<CarResultsScreen> {
  String _selectedSort = 'Popular';

  static const _sortOptions = [
    'Popular',
    'Verified',
    'Newest to Oldest',
    'Oldest to Newest',
    'Price Highest to Lowest',
    'Price Lowest to Highest',
  ];

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFCFCF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Sort',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 28 / 18,
                      letterSpacing: 0,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE8E9EB), width: 1),
                  ),
                ),
                child: Column(
                  children: _sortOptions.map((item) {
                    final selected = item == _selectedSort;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedSort = item);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Color(0xFFE8E9EB), width: 1),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                  letterSpacing: 0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check,
                                color: Color(0xFF2258A8),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCFCFCF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Filter',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 28 / 18,
                    letterSpacing: 0,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Filter options will be added here.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Results',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 28 / 15,
            letterSpacing: 0,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.tune, color: Colors.black87, size: 20),
          ),
          IconButton(
            onPressed: _openSortSheet,
            icon: const Icon(Icons.swap_vert, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 2),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
        ),
      ),
      body: ref.watch(rentalCarsProvider(widget.rentalDuration)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (cars) => RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(rentalCarsProvider(widget.rentalDuration).future),
              child: cars.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 400,
                        child: Center(child: Text('No rental cars found')),
                      ),
                    )
                  : GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: 340,
                      ),
                      itemCount: cars.length,
                      itemBuilder: (_, i) => _CarCard(car: cars[i]),
                    ),
            ),
          ),
    );
  }
}

class _CarCard extends ConsumerStatefulWidget {
  final RentalCarModel car;
  const _CarCard({required this.car});

  @override
  ConsumerState<_CarCard> createState() => _CarCardState();
}

class _CarCardState extends ConsumerState<_CarCard> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(7.38),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _RentalCarDetailScreen(car: car),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(7.38),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: 101,
                    width: double.infinity,
                    child: car.images.isEmpty
                        ? Container(
                            color: const Color(0xFFE8E8E8),
                            child: const Icon(Icons.directions_car,
                                size: 40, color: Colors.grey),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: car.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, i) => Image.network(
                              car.images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE8E8E8),
                                child: const Icon(Icons.directions_car,
                                    size: 40, color: Colors.grey),
                              ),
                            ),
                          ),
                  ),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _TopCircleButton(icon: Icons.reply_outlined),
                        SizedBox(width: 5),
                        _TopCircleButton(icon: Icons.favorite_border),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x63000000),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              color: Colors.white, size: 9),
                          const SizedBox(width: 3),
                          Text(
                            car.images.length > 1
                                ? '${_currentPage + 1}/${car.images.length}'
                                : car.photoCount,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF141414),
                        height: 1.3,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Spec(
                            icon: Icons.calendar_month_outlined,
                            value: car.year),
                        const SizedBox(width: 10),
                        _Spec(
                            icon: Icons.airline_seat_recline_normal_outlined,
                            value: car.seats.toString()),
                        const SizedBox(width: 10),
                        _Spec(
                            icon: Icons.door_front_door_outlined,
                            value: car.doors.toString()),
                        const SizedBox(width: 10),
                        _Spec(
                            icon: Icons.luggage_outlined,
                            value: car.luggage.toString()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      car.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _RentBox(
                              title: 'DAILY RENT',
                              price: car.priceDaily,
                              km: car.kmDay),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RentBox(
                              title: 'MONTHLY RENT',
                              price: car.priceMonthly,
                              km: car.kmMonth),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (car.hasDayRental) ...[
                          const Icon(Icons.info_outline,
                              size: 13, color: Colors.black87),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '1 Day Rental',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                  fontSize: 11, color: const Color(0xFF1E1E1E)),
                            ),
                          ),
                        ],
                        if (car.hasInsurance) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check,
                              size: 13, color: Color(0xFF0EAF2D)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Insurance',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                  fontSize: 11, color: const Color(0xFF1E1E1E)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.black87),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            car.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: const Color(0xFF1E1E1E)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionButton(icon: Icons.phone_outlined, onTap: () {}),
                        const SizedBox(width: 8),
                        _ActionButton(
                            icon: Icons.chat_bubble_outline, onTap: _openChat),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    try {
      final chatId =
          await ref.read(chatActionsProvider).openOrCreateChatForListing(
                listingId: widget.car.id,
                sellerId: widget.car.sellerId,
              );
      if (!mounted) return;
      context.push('/chat/$chatId');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.toLowerCase().contains('please sign in first')) {
        context.push(RouteNames.onboarding);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _RentalCarDetailScreen extends ConsumerStatefulWidget {
  final RentalCarModel car;
  const _RentalCarDetailScreen({required this.car});

  @override
  ConsumerState<_RentalCarDetailScreen> createState() =>
      _RentalCarDetailScreenState();
}

class _RentalCarDetailScreenState
    extends ConsumerState<_RentalCarDetailScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

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
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                            decoration: BoxDecoration(
                              color: index == _currentPage
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.45),
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
                            _DetailTopCircleButton(icon: Icons.reply_outlined),
                            SizedBox(width: 10),
                            _DetailTopCircleButton(icon: Icons.favorite_border),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${car.name} ${car.carModel}'.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 17.24,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF141414),
                        height: 31.04 / 17.24,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _DetailSpec(
                            icon: Icons.calendar_month_outlined,
                            value: car.year),
                        const SizedBox(width: 14),
                        _DetailSpec(
                            icon: Icons.airline_seat_recline_normal_outlined,
                            value: car.seats.toString()),
                        const SizedBox(width: 14),
                        _DetailSpec(
                            icon: Icons.car_rental_outlined,
                            value: car.doors.toString()),
                        const SizedBox(width: 14),
                        _DetailSpec(
                            icon: Icons.luggage_outlined,
                            value: car.luggage.toString()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DetailRentBox(
                        title: 'DAILY RENT',
                        price: car.priceDaily,
                        subText: car.kmDay,
                        extraText: 'AED 5 for each additional km'),
                    const SizedBox(height: 8),
                    _DetailRentBox(
                        title: 'MONTHLY RENT',
                        price: car.priceMonthly,
                        subText: car.kmMonth,
                        extraText: 'AED 5 for each additional km'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 15, color: Color(0xFF505050)),
                        const SizedBox(width: 5),
                        Text(
                          '1 Day Rental Available',
                          style: GoogleFonts.poppins(
                            fontSize: 11.62,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF505050),
                            height: 17.06 / 11.62,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.check,
                            size: 15, color: Color(0xFF0EAF2D)),
                        const SizedBox(width: 5),
                        Text(
                          'Basic Insurance',
                          style: GoogleFonts.poppins(
                            fontSize: 11.62,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF505050),
                            height: 17.06 / 11.62,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 18),
                    Text(
                      'Car Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 19.06,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 31.04 / 19.06,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _overviewRow('Interior Color', 'Black'),
                    _overviewRow('Trim', 'Other'),
                    _overviewRow('Horsepower', '200 - 299 HP'),
                    const SizedBox(height: 18),
                    const Divider(
                        height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                            child: _detailAction(Icons.phone_outlined, 'Call')),
                        const SizedBox(width: 8),
                        Expanded(child: _whatsAppAction(onTap: _openChat)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _detailAction(
                                Icons.chat_bubble_outline, 'SMS',
                                onTap: _openChat)),
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
                letterSpacing: 0,
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
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat() async {
    try {
      final chatId =
          await ref.read(chatActionsProvider).openOrCreateChatForListing(
                listingId: widget.car.id,
                sellerId: widget.car.sellerId,
              );
      if (!mounted) return;
      context.push('/chat/$chatId');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.toLowerCase().contains('please sign in first')) {
        context.push(RouteNames.onboarding);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _detailAction(IconData icon, String? label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD9D9D9)),
          color: Colors.white,
        ),
        child: label == null
            ? Center(
                child: Icon(icon, size: 18, color: const Color(0xFF2258A8)),
              )
            : Row(
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
                      letterSpacing: 0,
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

class _DetailTopCircleButton extends StatelessWidget {
  final IconData icon;
  const _DetailTopCircleButton({required this.icon});

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
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DetailRentBox extends StatelessWidget {
  final String title;
  final String price;
  final String subText;
  final String extraText;
  const _DetailRentBox({
    required this.title,
    required this.price,
    required this.subText,
    required this.extraText,
  });

  @override
  Widget build(BuildContext context) {
    final parts = price.split(' ');
    final currency = parts.isNotEmpty ? parts.first : price;
    final amount = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 24.24 / 12.12,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  subText,
                  style: GoogleFonts.poppins(
                    fontSize: 10.84,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF505050),
                    height: 24.24 / 10.84,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: currency,
                      style: GoogleFonts.poppins(
                        fontSize: 17.88,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 24.24 / 17.88,
                        letterSpacing: 0,
                      ),
                    ),
                    TextSpan(
                      text: amount.isEmpty ? '' : ' $amount',
                      style: GoogleFonts.poppins(
                        fontSize: 17.88,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 24.24 / 17.88,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                extraText,
                style: GoogleFonts.poppins(
                  fontSize: 10.84,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF505050),
                  height: 24.24 / 10.84,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x99FFFFFF)),
        color: const Color(0x140F172A),
      ),
      child: Icon(icon, color: Colors.white, size: 12),
    );
  }
}

class _Spec extends StatelessWidget {
  final IconData icon;
  final String value;
  const _Spec({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF4A4A4A)),
        const SizedBox(width: 3),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: const Color(0xFF303030),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RentBox extends StatelessWidget {
  final String title;
  final String price;
  final String km;
  const _RentBox({
    required this.title,
    required this.price,
    required this.km,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
          Text(
            km,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: const Color(0xFF343434),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 31,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
          color: const Color(0xFFF7F7F7),
        ),
        child: Icon(icon, color: const Color(0xFF2258A8), size: 14),
      ),
    );
  }
}
