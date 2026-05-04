import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/favorite_button.dart';
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
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';
  Set<String> _selectedSeats = {};
  Set<String> _selectedColors = {};
  Set<String> _selectedYears = {};
  Set<String> _selectedInsurance = {};
  Set<String> _selectedModels = {};
  Set<String> _selectedDoors = {};
  Set<String> _selectedLuggage = {};
  Set<String> _selectedDailyRental = {};
  Set<String> _selectedTrim = {};
  Set<String> _selectedHorsepower = {};
  Set<String> _selectedLocation = {};
  Set<String> _selectedRentalDuration = {};
  List<RentalCarModel> _allCars = [];

  static const _sortOptions = [
    'Popular',
    'Verified',
    'Newest to Oldest',
    'Oldest to Newest',
    'Price Highest to Lowest',
    'Price Lowest to Highest',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RentalCarModel> _filterCars(List<RentalCarModel> cars) {
    return cars.where((car) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        final values = [
          car.name,
          car.subtitle,
          car.carModel,
          car.year,
          car.location,
          car.trim,
          car.horsepower,
          car.rentalDuration,
          car.sellerName,
        ].join(' ').toLowerCase();
        if (!values.contains(query)) return false;
      }

      // Filter by rental duration (from category selection)
      if (widget.rentalDuration != 'all') {
        if (car.rentalDuration != widget.rentalDuration) return false;
      }

      if (_selectedSeats.isNotEmpty && !_selectedSeats.contains('All')) {
        if (!_selectedSeats.contains(car.seats.toString())) return false;
      }
      if (_selectedColors.isNotEmpty && !_selectedColors.contains('All')) {
        if (!_selectedColors.contains(car.interiorColor)) return false;
      }
      if (_selectedYears.isNotEmpty && !_selectedYears.contains('All')) {
        if (!_selectedYears.contains(car.year)) return false;
      }
      if (_selectedInsurance.isNotEmpty) {
        final hasIns = car.hasInsurance;
        final wantsWith = _selectedInsurance.contains('With Insurance');
        final wantsWithout = _selectedInsurance.contains('Without Insurance');
        if (wantsWith && !hasIns) return false;
        if (wantsWithout && hasIns) return false;
      }
      if (_selectedModels.isNotEmpty && !_selectedModels.contains('All')) {
        if (!_selectedModels.contains(car.carModel)) return false;
      }
      if (_selectedDoors.isNotEmpty && !_selectedDoors.contains('All')) {
        if (!_selectedDoors.contains(car.doors.toString())) return false;
      }
      if (_selectedLuggage.isNotEmpty && !_selectedLuggage.contains('All')) {
        if (!_selectedLuggage.contains(car.luggage.toString())) return false;
      }
      if (_selectedDailyRental.isNotEmpty) {
        final hasDaily = car.hasDayRental;
        final wantsYes = _selectedDailyRental.contains('Yes');
        final wantsNo = _selectedDailyRental.contains('No');
        if (wantsYes && !hasDaily) return false;
        if (wantsNo && hasDaily) return false;
      }
      if (_selectedTrim.isNotEmpty && !_selectedTrim.contains('All')) {
        if (!_selectedTrim.contains(car.trim)) return false;
      }
      if (_selectedHorsepower.isNotEmpty &&
          !_selectedHorsepower.contains('All')) {
        if (!_selectedHorsepower.contains(car.horsepower)) return false;
      }
      if (_selectedLocation.isNotEmpty && !_selectedLocation.contains('All')) {
        if (!_selectedLocation.contains(car.location)) return false;
      }
      if (_selectedRentalDuration.isNotEmpty &&
          !_selectedRentalDuration.contains('All')) {
        if (!_selectedRentalDuration.contains(car.rentalDuration)) return false;
      }
      return true;
    }).toList();
  }

  List<RentalCarModel> _sortCars(List<RentalCarModel> cars) {
    final sorted = List<RentalCarModel>.from(cars);
    switch (_selectedSort) {
      case 'Price Highest to Lowest':
        sorted.sort((a, b) => b.dailyRent.compareTo(a.dailyRent));
        break;
      case 'Price Lowest to Highest':
        sorted.sort((a, b) => a.dailyRent.compareTo(b.dailyRent));
        break;
      case 'Oldest to Newest':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Newest to Oldest':
      case 'Popular':
      case 'Verified':
      default:
        break;
    }
    return sorted;
  }

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
                        context.pop();
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RentalFilterScreen(
          allCars: _allCars,
          selectedSeats: _selectedSeats,
          selectedColors: _selectedColors,
          selectedYears: _selectedYears,
          selectedInsurance: _selectedInsurance,
          selectedModels: _selectedModels,
          selectedDoors: _selectedDoors,
          selectedLuggage: _selectedLuggage,
          selectedDailyRental: _selectedDailyRental,
          selectedTrim: _selectedTrim,
          selectedHorsepower: _selectedHorsepower,
          selectedLocation: _selectedLocation,
          selectedRentalDuration: _selectedRentalDuration,
          onApply: (seats, colors, years, insurance, models, doors, luggage,
              dailyRental, trim, horsepower, location, rentalDuration) {
            setState(() {
              _selectedSeats = seats;
              _selectedColors = colors;
              _selectedYears = years;
              _selectedInsurance = insurance;
              _selectedModels = models;
              _selectedDoors = doors;
              _selectedLuggage = luggage;
              _selectedDailyRental = dailyRental;
              _selectedTrim = trim;
              _selectedHorsepower = horsepower;
              _selectedLocation = location;
              _selectedRentalDuration = rentalDuration;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Colors.black87),
        ),
        title: Text(
          'Results',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _openFilterSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SvgPicture.asset('assets/icons/filter.svg',
                  width: 20, height: 20),
            ),
          ),
          GestureDetector(
            onTap: _openSortSheet,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SvgPicture.asset('assets/icons/bars_sort.svg',
                  width: 20, height: 20),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
        ),
      ),
      body: ref.watch(rentalCarsProvider(widget.rentalDuration)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (cars) {
              _allCars = cars;
              final filtered = _sortCars(_filterCars(cars));
              return RefreshIndicator(
                onRefresh: () => ref
                    .refresh(rentalCarsProvider(widget.rentalDuration).future),
                child: filtered.isEmpty
                    ? const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 400,
                          child: Center(child: Text('No rental cars found')),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFFC2C2C2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 12),
                                    const Icon(Icons.search,
                                        size: 16, color: Colors.black87),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                          controller: _searchCtrl,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            height: 1,
                                            color: Colors.black87,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.only(
                                                    top: 12, bottom: 12),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            hintText: 'Search rental cars...',
                                            hintStyle: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              height: 1,
                                              color: const Color(0xFF8A8A8A),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                mainAxisExtent: 340,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _CarCard(car: filtered[i]),
                            ),
                          ],
                        ),
                      ),
              );
            },
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        const _TopCircleButton(icon: Icons.reply_outlined),
                        const SizedBox(width: 5),
                        FavoriteButton(
                          listingId: car.id,
                          size: 24,
                          backgroundColor: const Color(0x100F172A),
                          showShadow: false,
                          unselectedIconColor: Colors.white,
                          selectedIconColor: Colors.red,
                        ),
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
                      onTap: () => context.pop(),
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
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _DetailTopCircleButton(
                              icon: Icons.reply_outlined,
                              onTap: _shareItem,
                            ),
                            const SizedBox(width: 10),
                            FavoriteButton(listingId: car.id, size: 24),
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
                            child: _detailAction(Icons.message_outlined, 'Chat',
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

  void _shareItem() {
    final carName = '${widget.car.name} ${widget.car.carModel}'.trim();
    final shareText =
        'Check out this rental car: $carName - AED ${widget.car.priceDaily}/day on Afghan Deals Pro';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Share Listing',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.copy, color: Color(0xFF2258A8)),
                title: Text(
                  'Copy to Clipboard',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: shareText),
                  );
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied: $carName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Color(0xFF2258A8)),
                title: Text(
                  'Share via Message',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Shared: $carName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Color(0xFF2258A8)),
                title: Text(
                  'Copy Link',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                        text: 'afghan-deals-pro://car/${widget.car.id}'),
                  );
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link copied for $carName'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
  final Function()? onTap;
  const _DetailTopCircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
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
      ),
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
        color: const Color(0x100F172A),
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

// ── Rental Filter Screen ────────────────────────────────────────────────────

class _RentalFilterScreen extends StatefulWidget {
  final List<RentalCarModel> allCars;
  final Set<String> selectedSeats;
  final Set<String> selectedColors;
  final Set<String> selectedYears;
  final Set<String> selectedInsurance;
  final Set<String> selectedModels;
  final Set<String> selectedDoors;
  final Set<String> selectedLuggage;
  final Set<String> selectedDailyRental;
  final Set<String> selectedTrim;
  final Set<String> selectedHorsepower;
  final Set<String> selectedLocation;
  final Set<String> selectedRentalDuration;
  final Function(
      Set<String>,
      Set<String>,
      Set<String>,
      Set<String>,
      Set<String>,
      Set<String>,
      Set<String>,
      Set<String>,
      Set<String>,
      Set<String>,
      Set<String>,
      Set<String>) onApply;

  const _RentalFilterScreen({
    required this.allCars,
    required this.selectedSeats,
    required this.selectedColors,
    required this.selectedYears,
    required this.selectedInsurance,
    required this.selectedModels,
    required this.selectedDoors,
    required this.selectedLuggage,
    required this.selectedDailyRental,
    required this.selectedTrim,
    required this.selectedHorsepower,
    required this.selectedLocation,
    required this.selectedRentalDuration,
    required this.onApply,
  });

  @override
  State<_RentalFilterScreen> createState() => _RentalFilterScreenState();
}

class _RentalFilterScreenState extends State<_RentalFilterScreen> {
  late Set<String> _seats;
  late Set<String> _colors;
  late Set<String> _years;
  late Set<String> _insurance;
  late Set<String> _models;
  late Set<String> _doors;
  late Set<String> _luggage;
  late Set<String> _dailyRental;
  late Set<String> _trim;
  late Set<String> _horsepower;
  late Set<String> _location;
  late Set<String> _rentalDuration;
  String _activeFilter = 'seats';

  late List<String> _seatList;
  late List<String> _colorList;
  late List<String> _yearList;
  late List<String> _modelList;
  late List<String> _doorList;
  late List<String> _luggageList;
  late List<String> _trimList;
  late List<String> _horsepowerList;
  late List<String> _locationList;
  late List<String> _rentalDurationList;

  @override
  void initState() {
    super.initState();
    _seats = Set.from(widget.selectedSeats);
    _colors = Set.from(widget.selectedColors);
    _years = Set.from(widget.selectedYears);
    _insurance = Set.from(widget.selectedInsurance);
    _models = Set.from(widget.selectedModels);
    _doors = Set.from(widget.selectedDoors);
    _luggage = Set.from(widget.selectedLuggage);
    _dailyRental = Set.from(widget.selectedDailyRental);
    _trim = Set.from(widget.selectedTrim);
    _horsepower = Set.from(widget.selectedHorsepower);
    _location = Set.from(widget.selectedLocation);
    _rentalDuration = Set.from(widget.selectedRentalDuration);

    // Extract unique values from cars
    _seatList = [
      'All',
      ...widget.allCars.map((c) => c.seats.toString()).toSet().toList()..sort()
    ];
    _colorList = [
      'All',
      ...widget.allCars
          .where((c) => c.interiorColor.isNotEmpty)
          .map((c) => c.interiorColor)
          .toSet()
          .toList()
        ..sort()
    ];
    _yearList = [
      'All',
      ...widget.allCars.map((c) => c.year).toSet().toList()
        ..sort((a, b) => b.compareTo(a))
    ];
    _modelList = [
      'All',
      ...widget.allCars
          .where((c) => c.carModel.isNotEmpty)
          .map((c) => c.carModel)
          .toSet()
          .toList()
        ..sort()
    ];
    _doorList = [
      'All',
      ...widget.allCars.map((c) => c.doors.toString()).toSet().toList()..sort()
    ];
    _luggageList = [
      'All',
      ...widget.allCars.map((c) => c.luggage.toString()).toSet().toList()
        ..sort()
    ];
    _trimList = [
      'All',
      ...widget.allCars
          .where((c) => c.trim.isNotEmpty)
          .map((c) => c.trim)
          .toSet()
          .toList()
        ..sort()
    ];
    _horsepowerList = [
      'All',
      ...widget.allCars
          .where((c) => c.horsepower.isNotEmpty)
          .map((c) => c.horsepower)
          .toSet()
          .toList()
        ..sort()
    ];
    _locationList = [
      'All',
      ...widget.allCars.map((c) => c.location).toSet().toList()..sort()
    ];
    _rentalDurationList = [
      'All',
      ...widget.allCars.map((c) => c.rentalDuration).toSet().toList()..sort()
    ];
  }

  void _clearAll() => setState(() {
        _seats.clear();
        _colors.clear();
        _years.clear();
        _insurance.clear();
        _models.clear();
        _doors.clear();
        _luggage.clear();
        _dailyRental.clear();
        _trim.clear();
        _horsepower.clear();
        _location.clear();
        _rentalDuration.clear();
        _activeFilter = 'seats';
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text('Filter',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: Text('Clear All',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF2258A8))),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              widget.onApply(
                  _seats,
                  _colors,
                  _years,
                  _insurance,
                  _models,
                  _doors,
                  _luggage,
                  _dailyRental,
                  _trim,
                  _horsepower,
                  _location,
                  _rentalDuration);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2258A8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('Apply',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Panel
            Container(
              width: (MediaQuery.of(context).size.width - 34) / 2,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLeftItem(
                        'rentalDuration', 'Rental Duration', Icons.access_time),
                    _buildLeftItem('seats', 'Seats', Icons.event_seat),
                    _buildLeftItem('model', 'Car Model', Icons.directions_car),
                    _buildLeftItem('year', 'Year', Icons.calendar_today),
                    _buildLeftItem('color', 'Interior Color', Icons.palette),
                    _buildLeftItem('doors', 'Doors', Icons.meeting_room),
                    _buildLeftItem('luggage', 'Luggage', Icons.luggage),
                    _buildLeftItem('trim', 'Trim', Icons.info_outline),
                    _buildLeftItem('horsepower', 'Horsepower', Icons.bolt),
                    _buildLeftItem('location', 'Location', Icons.location_on),
                    _buildLeftItem('insurance', 'Insurance', Icons.shield),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Right Panel
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFD0D0D0), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildRightPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftItem(String id, String label, IconData icon) {
    final active = _activeFilter == id;
    final hasVal = switch (id) {
      'seats' => _seats.isNotEmpty,
      'model' => _models.isNotEmpty,
      'year' => _years.isNotEmpty,
      'color' => _colors.isNotEmpty,
      'doors' => _doors.isNotEmpty,
      'luggage' => _luggage.isNotEmpty,
      'dailyRental' => _dailyRental.isNotEmpty,
      'trim' => _trim.isNotEmpty,
      'horsepower' => _horsepower.isNotEmpty,
      'location' => _location.isNotEmpty,
      'rentalDuration' => _rentalDuration.isNotEmpty,
      'insurance' => _insurance.isNotEmpty,
      _ => false,
    };

    return InkWell(
      onTap: () => setState(() => _activeFilter = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border:
              Border(bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color:
                    active ? const Color(0xFF2258A8) : const Color(0xFF7C7D88)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: 0,
                  color: active ? const Color(0xFF2258A8) : Colors.black,
                ),
              ),
            ),
            if (hasVal)
              const Icon(Icons.check_circle,
                  color: Color(0xFF00BA00), size: 21),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return switch (_activeFilter) {
      'rentalDuration' => ListView(
          children: _rentalDurationList
              .map((duration) => _buildCheckRow(
                  duration,
                  _rentalDuration,
                  (v) => _rentalDuration.contains(v)
                      ? _rentalDuration.remove(v)
                      : _rentalDuration.add(v)))
              .toList()),
      'seats' => ListView(
          children: _seatList
              .map((seat) => _buildCheckRow(seat, _seats,
                  (v) => _seats.contains(v) ? _seats.remove(v) : _seats.add(v)))
              .toList()),
      'model' => ListView(
          children: _modelList
              .map((model) => _buildCheckRow(
                  model,
                  _models,
                  (v) =>
                      _models.contains(v) ? _models.remove(v) : _models.add(v)))
              .toList()),
      'year' => ListView(
          children: _yearList
              .map((year) => _buildCheckRow(year, _years,
                  (v) => _years.contains(v) ? _years.remove(v) : _years.add(v)))
              .toList()),
      'color' => ListView(
          children: _colorList
              .map((color) => _buildCheckRow(
                  color,
                  _colors,
                  (v) =>
                      _colors.contains(v) ? _colors.remove(v) : _colors.add(v)))
              .toList()),
      'doors' => ListView(
          children: _doorList
              .map((door) => _buildCheckRow(door, _doors,
                  (v) => _doors.contains(v) ? _doors.remove(v) : _doors.add(v)))
              .toList()),
      'luggage' => ListView(
          children: _luggageList
              .map((luggage) => _buildCheckRow(
                  luggage,
                  _luggage,
                  (v) => _luggage.contains(v)
                      ? _luggage.remove(v)
                      : _luggage.add(v)))
              .toList()),
      'dailyRental' => ListView(
          children: ['Yes', 'No']
              .map((rental) => _buildCheckRow(
                  rental,
                  _dailyRental,
                  (v) => _dailyRental.contains(v)
                      ? _dailyRental.remove(v)
                      : _dailyRental.add(v)))
              .toList()),
      'trim' => ListView(
          children: _trimList
              .map((trim) => _buildCheckRow(trim, _trim,
                  (v) => _trim.contains(v) ? _trim.remove(v) : _trim.add(v)))
              .toList()),
      'horsepower' => ListView(
          children: _horsepowerList
              .map((hp) => _buildCheckRow(
                  hp,
                  _horsepower,
                  (v) => _horsepower.contains(v)
                      ? _horsepower.remove(v)
                      : _horsepower.add(v)))
              .toList()),
      'location' => ListView(
          children: _locationList
              .map((loc) => _buildCheckRow(
                  loc,
                  _location,
                  (v) => _location.contains(v)
                      ? _location.remove(v)
                      : _location.add(v)))
              .toList()),
      'insurance' => ListView(
          children: ['With Insurance', 'Without Insurance']
              .map((ins) => _buildCheckRow(
                  ins,
                  _insurance,
                  (v) => _insurance.contains(v)
                      ? _insurance.remove(v)
                      : _insurance.add(v)))
              .toList()),
      _ => const SizedBox(),
    };
  }

  Widget _buildCheckRow(
      String label, Set<String> selected, Function(String) onTap) {
    final isSelected = selected.contains(label);
    return InkWell(
      onTap: () => setState(() => onTap(label)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border:
              Border(bottom: BorderSide(color: Color(0xFFE8E9EB), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2258A8) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2258A8)
                      : const Color(0xFFBBBBBB),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: 0,
                  color: isSelected ? const Color(0xFF2258A8) : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
